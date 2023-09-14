import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/pages/v1/dapp_withdraw_funds_v1.dart';
import '../dapp_add_funds.dart';
import 'dapp_advanced_funds_v1.dart';

/// The tabs for interacting with the V1 contract.
class DappTabsV1 extends StatefulWidget {
  final OrchidWeb3Context? web3Context;
  final EthereumAddress? signer;
  final AccountDetail? accountDetail;

  const DappTabsV1({
    Key? key,
    required this.web3Context,
    required this.signer,
    required this.accountDetail,
  }) : super(key: key);

  @override
  State<DappTabsV1> createState() => _DappTabsV1State();
}

class _DappTabsV1State extends State<DappTabsV1> with TickerProviderStateMixin {
  late TabController tabController;

  bool get _enabled {
    return widget.web3Context != null &&
        widget.signer != null
        // right now this is a stand-in to make sure the contacts are found and working
        &&
        widget.accountDetail?.lotteryPot != null;
  }

  static int _initialIndex = 0;
  int _selectedTab = _initialIndex;

  @override
  void initState() {
    super.initState();
    tabController =
        TabController(length: 3, initialIndex: _initialIndex, vsync: this);
    tabController.addListener(_tabChanged);
  }

  void _tabChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var tabStyle = OrchidText.button;
    var selectedTabStyle = OrchidText.button.bold;

    final tab = (text, index) => Tab(
        child: FittedBox(
            child: Text(text,
                style: tabController.index == index
                    ? selectedTabStyle
                    : tabStyle)));

    final tabView = (child) => Padding(
          padding: const EdgeInsets.only(top: 24.0),
          // Note: the scrollview here accommodates the changing tab height
          // Note: during the tab transition from taller to shorter.
          child: SingleChildScrollView(
            child: Center(child: child),
          ),
        );

    // Rebuild tab form fields on context change (chain or account).
    // log("XXX: buildTabs web3Context id = ${widget.web3Context?.id}");
    final contextKey = Key(widget.web3Context?.id.toString() ?? '');

    return SizedBox(
      // Note: We seem to have to set a fixed height outside the scaffold here.
      height: [450.0, 450.0, 900.0][_selectedTab],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size(double.infinity, 50),
          child: TabBar(
            controller: tabController,
            indicatorColor: OrchidColors.tappable,
            tabs: [
              tab(s.add1, 0),
              tab(s.withdraw, 1),
              tab(s.advanced1, 2),
            ],
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            tabView(
              AddFundsPane(
                tokenType:
                    widget.web3Context?.chain.nativeCurrency ?? Tokens.TOK,
                key: contextKey,
                enabled: _enabled,
                context: widget.web3Context,
                signer: widget.signer,
                addFunds: _orchidAddFunds,
              ),
            ),
            tabView(
              WithdrawFundsPaneV1(
                key: contextKey,
                enabled: _enabled,
                context: widget.web3Context,
                pot: widget.accountDetail?.lotteryPot,
                signer: widget.signer,
              ),
            ),
            tabView(
              AdvancedFundsPaneV1(
                key: contextKey,
                enabled: _enabled,
                context: widget.web3Context,
                pot: widget.accountDetail?.lotteryPot,
                signer: widget.signer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Defers construction of the contract until needed
  Future<List<String> /*TransactionId*/ > _orchidAddFunds({
    required OrchidWallet? wallet,
    required EthereumAddress? signer,
    required Token addBalance,
    required Token addEscrow,
  }) async {
    if (signer == null || wallet == null) {
      throw Exception("No signer");
    }
    return OrchidWeb3V1(widget.web3Context!).orchidAddFunds(
      wallet: wallet,
      signer: signer,
      addBalance: addBalance,
      addEscrow: addEscrow,
    );
  }
}
