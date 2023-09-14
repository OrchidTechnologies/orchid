import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/pages/v0/dapp_tabs_v0.dart';
import 'dapp_home_base.dart';
import 'dapp_home_header.dart';
import '../dapp/orchid/dapp_transaction_list.dart';
import 'v1/dapp_tabs_v1.dart';

class DappHome extends StatefulWidget {
  const DappHome({Key? key}) : super(key: key);

  @override
  State<DappHome> createState() => DappHomeState();
}

class DappHomeState extends DappHomeStateBase<DappHome> {
  // This must be wide enough to accommodate the tab names.
  final mainColumnWidth = 800.0;
  final altColumnWidth = 500.0;

  // TODO: Encapsulate this in a provider builder widget (ala TokenPriceBuilder)
  // TODO: Before that we need to add a controller to our PollingBuilder to allow
  // TODO: for refresh on demand.
  AccountDetailPoller? _funderAccountDetail;

  EthereumAddress? _signer;
  final _signerField = AddressValueFieldController();

  bool get _hasAccount => _signer != null && web3Context?.walletAddress != null;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _signerField.addListener(_signerFieldChanged);
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
        _signer =
            EthereumAddress.from('0x5eea55E63a62138f51D028615e8fd6bb26b8D354');
        _signerField.textController.text = _signer.toString();
      });
    }
  }

  void _signerFieldChanged() {
    // signer field changed?
    var oldSigner = _signer;
    _signer = _signerField.value;
    if (_signer != oldSigner) {
      _selectedAccountChanged();
    }

    // Update UI
    setState(() {});
  }

  void _accountDetailUpdated() {
    setState(() {});
  }

  // TODO: replace this account detail management with a provider builder
  void _clearAccountDetail() {
    _funderAccountDetail?.cancel();
    _funderAccountDetail?.removeListener(_accountDetailUpdated);
    _funderAccountDetail = null;
  }

  // TODO: replace this account detail management with a provider builder
  // Start polling the correct account
  void _selectedAccountChanged() async {
    // log("XXX: selectedAccountChanged");
    _clearAccountDetail();
    if (_hasAccount) {
      // Avoid starting the poller in the rare case where there are no contracts
      if (contractVersionSelected != null) {
        var account = Account.fromSignerAddress(
          signerAddress: _signer!,
          version: contractVersionSelected!,
          funder: web3Context!.walletAddress!,
          chainId: web3Context!.chain.chainId,
        );
        _funderAccountDetail = AccountDetailPoller(
          account: account,
          pollingPeriod: Duration(seconds: 10),
        );
        _funderAccountDetail!.addListener(_accountDetailUpdated);
        _funderAccountDetail!.startPolling();
      }
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
          deployContract: deployContract,
          connectEthereum: connectEthereum,
          disconnect: disconnect,
        ).padx(24).top(30).bottom(24),
        _buildMainColumn(),
      ],
    );
  }

  // main info column
  Expanded _buildMainColumn() {
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

                    // signer field
                    ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: altColumnWidth),
                        child: OrchidLabeledAddressField(
                          label: s.orchidIdentity,
                          controller: _signerField,
                          contentPadding: EdgeInsets.only(
                              top: 8, bottom: 18, left: 16, right: 16),
                        ).top(24).padx(8)),

                    // account card
                    AnimatedVisibility(
                      show: _hasAccount,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: altColumnWidth, maxWidth: altColumnWidth),
                        child: AccountCard(
                          // todo: the key here just allows us to expanded when details are available
                          // todo: maybe make that the default behavior of the card
                          key: Key(_funderAccountDetail?.funder.toString() ??
                              'null'),
                          minHeight: true,
                          showAddresses: false,
                          showContractVersion: false,
                          accountDetail: _funderAccountDetail,
                          // initiallyExpanded: _accountDetail != null,
                          initiallyExpanded: false,
                          // partial values from the connection panel
                          partialAccountFunderAddress:
                              web3Context?.walletAddress,
                          partialAccountSignerAddress: _signer,
                        ).top(24).padx(8),
                      ),
                    ),

                    // tabs
                    // Divider(color: Colors.white.withOpacity(0.3)).bottom(8),
                    AnimatedVisibility(
                      // show: _hasAccount,
                      show: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: altColumnWidth),
                        child: _buildTabs(),
                      ).padx(8).top(16),
                    ),

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

  Widget _buildTabs() {
    switch (contractVersionSelected) {
      case 0:
        return DappTabsV0(
          web3Context: web3Context,
          signer: _signer,
          accountDetail: _funderAccountDetail,
        );
      case 1:
      default:
        return DappTabsV1(
          web3Context: web3Context,
          signer: _signer,
          accountDetail: _funderAccountDetail,
        );
    }
  }

  // Refresh the wallet and account balances
  void _refreshUserData() {
    web3Context?.refresh();
    // TODO: Encapsulate this in a provider builder widget (ala TokenPriceBuilder)
    // TODO: Before that we need to add a controller to our PollingBuilder to allow
    // TODO: for refresh on demand.
    _funderAccountDetail?.refresh();
  }

  // Init a new context, disconnecting any old context and registering listeners
  @override
  void setNewContext(OrchidWeb3Context? web3Context) async {
    super.setNewContext(web3Context);

    try {
      _selectedAccountChanged();
    } catch (err) {
      log('set new context: error in selected account changed: $err');
    }
  }

  @override
  void onContractVersionChanged(int version) async {
    super.onContractVersionChanged(version);
    // todo: does this need to be done first?
    try {
      _selectedAccountChanged();
    } catch (err) {
      log('on contract version changed: error in selected account changed: $err');
    }
  }

  @override
  Future<void> disconnect() async {
    setState(() {
      _clearAccountDetail();
    });
    super.disconnect();
  }

  @override
  void dispose() {
    _signerField.removeListener(_signerFieldChanged);
    super.dispose();
  }
}
