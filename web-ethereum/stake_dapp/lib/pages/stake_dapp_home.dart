import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:orchid/dapp/orchid/dapp_transaction_list.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/token_value_widget_row.dart';
import 'package:orchid/orchid/builder/token_price_builder.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/pages/tabs/stake_tabs.dart';
import 'package:orchid/stake_dapp/orchid_web3_stake_v0.dart';
import 'dapp_home_base.dart';
import 'dapp_home_header.dart';
import 'tabs/add_stake_panel.dart';

class StakeDappHome extends StatefulWidget {
  const StakeDappHome({Key? key}) : super(key: key);

  @override
  State<StakeDappHome> createState() => _StakeDappHomeState();
}

class _StakeDappHomeState extends DappHomeStateBase<StakeDappHome> {
  // This must be wide enough to accommodate the tab names.
  final mainColumnWidth = 800.0;
  final altColumnWidth = 500.0;

  EthereumAddress? _stakee;
  final _stakeeField = AddressValueFieldController();

  bool get _hasAccount => _stakee != null && web3Context?.walletAddress != null;

  final _scrollController = ScrollController();

  Token? _currentStake;

  @override
  void initState() {
    super.initState();
    _stakeeField.addListener(_stakeeFieldChanged);
    initStateAsync();
  }

  void initStateAsync() async {
    await _supportTestAccountConnect();
    await checkForExistingConnectedAccounts();
  }

  Future<void> _supportTestAccountConnect() async {
    // (TESTING)
    if (OrchidUserParams().test) {
      await Future.delayed(Duration(seconds: 0), () {
        connectEthereum();
        _stakee =
            EthereumAddress.from('0x5eea55E63a62138f51D028615e8fd6bb26b8D354');
        _stakeeField.textController.text = _stakee.toString();
      });
    }
  }

  void _stakeeFieldChanged() {
    // signer field changed?
    var oldSigner = _stakee;
    _stakee = _stakeeField.value;
    if (_stakee != oldSigner) {
      _selectedStakeeChanged();
    }

    // Update UI
    setState(() {});
  }

  // Start polling the correct account
  // TODO: Poll this
  void _selectedStakeeChanged() async {
    if (_stakee != null && web3Context != null) {
      _currentStake =
          await OrchidWeb3StakeV0(web3Context!).orchidGetStake(_stakee!);
      log("XXX: heft = $_currentStake");
    } else {
      _currentStake = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DappHomeHeader(
          web3Context: web3Context,
          setNewContext: setNewContext,
          contractVersionsAvailable: contractVersionsAvailable,
          contractVersionSelected: contractVersionSelected,
          selectContractVersion: selectContractVersion,
          // deployContract: deployContract,
          connectEthereum: connectEthereum,
          disconnect: disconnect,
          showChainSelector: false,
        ).padx(24).top(30).bottom(24),
        _buildMainColumn(),
      ],
    );
  }

  // main info column
  Widget _buildMainColumn() {
    return TokenPriceBuilder(
        tokenType: Tokens.OXT,
        builder: (USD? tokenPrice) {
          return _buildMainColumnWith(tokenPrice);
        });
  }

  Widget _buildMainColumnWith(USD? price) {
    if (web3Context != null && web3Context!.chain != Chains.Ethereum)
      return _buildWrongChainPanel();

    return Expanded(
      child: Theme(
        data: Theme.of(context).copyWith(
          highlightColor: OrchidColors.tappable,
          scrollbarTheme: ScrollbarThemeData(
            thumbColor:
                MaterialStateProperty.all(Colors.white.withOpacity(0.4)),
            // isAlwaysShown: true,
            trackVisibility: MaterialStateProperty.all(true),
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            physics: OrchidPlatform.isWeb ? ClampingScrollPhysics() : null,
            controller: _scrollController,
            child: Center(
              child: SizedBox(
                width: mainColumnWidth,
                child: Column(
                  children: [
                    if (contractVersionsAvailable != null &&
                        contractVersionsAvailable!.isEmpty)
                      RoundedRect(
                        backgroundColor: OrchidColors.dark_background,
                        child: Text(s
                                .theOrchidContractHasntBeenDeployedOnThisChainYet)
                            .subtitle
                            .height(1.7)
                            .withColor(OrchidColors.status_yellow)
                            .pad(24),
                      ).center.bottom(24),

                    DappTransactionList(
                      web3Context: web3Context,
                      refreshUserData: _refreshUserData,
                      width: mainColumnWidth,
                    ).top(24),

                    // stakee field
                    ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: altColumnWidth),
                        child: OrchidLabeledAddressField(
                          label: "Stakee Address", // localize
                          controller: _stakeeField,
                          contentPadding: EdgeInsets.only(
                              top: 8, bottom: 18, left: 16, right: 16),
                        ).top(24).padx(8)),

                    // Current stake
                    AnimatedVisibility(
                      show: _stakee != null && _currentStake != null,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: altColumnWidth),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Current Stake").title.white,
                              ],
                            ),
                            TokenValueWidgetRow(
                              tokenType: Tokens.OXT,
                              value: _currentStake,
                              context: context,
                              child: Text(_currentStake?.formatCurrency(
                                          locale: context.locale,
                                          precision: 2) ??
                                      '')
                                  .title
                                  .white,
                              price: price,
                            ).top(8),
                          ],
                        ).top(24).padx(24),
                      ),
                    ),

                    // tabs
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: altColumnWidth),
                      child: StakeTabs(
                        web3Context: web3Context,
                        stakee: _stakee,
                        currentStake: _currentStake,
                        price: price,
                      ),
                    ).top(40),

                    // _buildFooter().padx(24).bottom(24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Refresh the wallet and account balances
  void _refreshUserData() {
    web3Context?.refresh();
  }

  // Init a new context, disconnecting any old context and registering listeners
  @override
  void setNewContext(OrchidWeb3Context? web3Context) async {
    super.setNewContext(web3Context);

    try {
      _selectedStakeeChanged();
    } catch (err) {
      log('set new context: error in selected account changed: $err');
    }
  }

  @override
  void onContractVersionChanged(int version) async {
    super.onContractVersionChanged(version);
    // todo: does this need to be done first?
    try {
      _selectedStakeeChanged();
    } catch (err) {
      log('on contract version changed: error in selected account changed: $err');
    }
  }

  @override
  Future<void> disconnect() async {
    // setState(() {
    //   _clearAccountDetail();
    // });
    super.disconnect();
  }

  @override
  void dispose() {
    _stakeeField.removeListener(_stakeeFieldChanged);
    super.dispose();
  }

  Widget _buildWrongChainPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RoundedRect(
          backgroundColor: OrchidColors.dark_background,
          child: Column(
            children: [
              Text(
                "Orchid staking requires a connection to the Ethereum main net.\n"
                "Please connect your wallet to Ethereum.",
                textAlign: TextAlign.center,
              ).body1.white.padx(24).top(24),
              Chains.Ethereum.icon.top(16).bottom(24),
            ],
          ),
        ),
      ],
    ).top(64);
  }
}

class DappHomeUtil {
  static void showRequestPendingMessage(BuildContext context) {
    AppDialogs.showAppDialog(
      context: context,
      title: context.s.checkWallet,
      bodyText: context.s.checkYourWalletAppOrExtensionFor,
    );
  }
}
