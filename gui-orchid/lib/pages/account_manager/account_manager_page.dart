import 'dart:async';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/account/account_selector.dart';
import 'package:orchid/orchid/account/account_store.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/account/account_detail_store.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';
import 'package:orchid/pages/account_manager/scan_paste_identity_dialog.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/pages/circuit/circuit_utils.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
import 'package:orchid/orchid/account/orchid_account_entry.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';
import 'package:orchid/pages/purchase/purchase_status.dart';
import 'package:orchid/util/listenable_builder.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:styled_text/styled_text.dart';

import '../../common/app_sizes.dart';
import '../app_routes.dart';
import 'account_manager_mock.dart';
import '../../orchid/account/account_view_model.dart';
import 'export_identity_dialog.dart';

class AccountManagerPage extends StatefulWidget {
  final bool openToImport;
  final bool openToPurchase;
  final Account? openToAccount;

  const AccountManagerPage({
    Key? key,
    this.openToImport = false,
    this.openToPurchase = false,
    this.openToAccount,
  }) : super(key: key);

  static Future<void> showAccount(BuildContext context, Account? account) {
    return Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return AccountManagerPage(openToAccount: account);
    }));
  }

  @override
  _AccountManagerPageState createState() => _AccountManagerPageState();
}

class _AccountManagerPageState extends State<AccountManagerPage> {
  List<StreamSubscription> _subs = [];
  List<StoredEthereumKey>? _identities;
  StoredEthereumKey? _selectedIdentity;

  AccountStore? _accountStore;
  late AccountDetailStore _accountDetailStore;

  var _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _accountDetailStore =
        AccountDetailStore(onAccountDetailChanged: _accountDetailChanged);
    initStateAsync();
  }

  void initStateAsync() async {
    // Listen for changes to identities
    UserPreferencesKeys().keys.stream().listen((keys) {
      _identities = keys;
      // Default if needed
      if (_selectedIdentity == null) {
        _setSelectedIdentity(_chooseDefaultIdentity(_identities!));
      }
      setState(() {});
    }).dispose(_subs);

    // Open to import, purchase, identity
    await _doOpenOptions();
  }

  void _setSelectedIdentity(StoredEthereumKey? identity) async {
    _selectedIdentity = identity;

    // Switch account stores
    if (_accountStore != null) {
      _accountStore!.removeListener(_accountsUpdated);
      _accountStore = null;
    }
    if (_selectedIdentity != null) {
      _accountStore = AccountStore(identity: _selectedIdentity!.ref());
      _accountStore!.addListener(_accountsUpdated);
      _accountStore!.load(waitForDiscovered: false);
    }

    setState(() {});
  }

  /// Pick an identitiy or null if empty
  static StoredEthereumKey? _chooseDefaultIdentity(
      List<StoredEthereumKey> identities) {
    return identities.isNotEmpty ? identities.first : null;
  }

  Future<void> _doOpenOptions() async {
    // Open to the supplied account
    if (widget.openToAccount != null) {
      // log('open to account: ${widget.openToAccount}');
      _setSelectedIdentity(widget.openToAccount!.signerKey);
    }

    // Open the import dialog after the UI has rendered.
    if (widget.openToImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _importAccount());
    }

    // Open the purchase dialog (once) after the account info has loaded.
    if (widget.openToPurchase && _accountStore != null) {
      await _accountStore!.load(waitForDiscovered: false);
      _accountStore!.addListener(() async {
        await _addFunds();
      });
    }
  }

  void _accountsUpdated() async {
    // update the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool identitiesEmpty = _accountStore == null;
    bool accountsEmpty = (_accountStore?.accounts ?? {}).isEmpty;
    log("XXX identities empty = $identitiesEmpty");
    log("XXX accounts empty = $accountsEmpty");

    return TitledPage(
      title: s.accounts,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _buildIdentitySelectorDropdownMenu(),
        )
      ],
      child: identitiesEmpty
          ? _buildNoIdentitiesEmptyState()
          : ListenableBuilderUtil(
              // not null due to identities check
              listenable: _accountStore!,
              builder: (context, snapshot) {
                return Stack(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildIdentityHeader(),
                            pady(8),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 28.0, right: 28.0),
                              child: PurchaseStatus(),
                            ),
                            pady(8),
                            Divider(height: 1),
                            Expanded(
                                child: accountsEmpty
                                    ? _buildNoAccountsEmptyState()
                                    : _buildAccountListAnnotatedActive()),
                          ],
                        ),
                      ),
                    ),

                    // The add funds
                    if (OrchidPlatform.hasPurchase)
                      SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: _buildAddFundsButton(),
                          ),
                        ),
                      ),
                  ],
                );
              }),
    );
  }

  Widget _buildIdentitySelectorDropdownMenu() {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: OrchidColors.dark_background,
        highlightColor: OrchidColors.purple_menu,
      ),
      child: PopupMenuButton<_IdentitySelectorMenuItem>(
        icon: OrchidAsset.svg.settings_gear,
        initialValue: _selectedIdentity != null
            ? _IdentitySelectorMenuItem(identity: _selectedIdentity!)
            : null,
        onSelected: (_IdentitySelectorMenuItem item) async {
          if (item.isIdentity) {
            _setSelectedIdentity(item.identity);
          } else {
            // null checked by init logic
            item.action!();
          }
        },
        itemBuilder: (BuildContext context) {
          var style = OrchidText.body1;
          var items = (_identities ?? []).map((StoredEthereumKey identity) {
            var item = _IdentitySelectorMenuItem(identity: identity);
            return PopupMenuItem<_IdentitySelectorMenuItem>(
              value: item,
              child: Text(item.formatIdentity(), style: style),
            );
          }).toList();

          // Add the import, export actions
          return items +
              [
                PopupMenuItem<_IdentitySelectorMenuItem>(
                    value: _IdentitySelectorMenuItem(action: _generateIdentity),
                    child: Text(s.newIdentity, style: style)),
                PopupMenuItem<_IdentitySelectorMenuItem>(
                    value: _IdentitySelectorMenuItem(action: _importIdentity),
                    child: Text(s.importIdentity, style: style)),
                PopupMenuItem<_IdentitySelectorMenuItem>(
                    value: _IdentitySelectorMenuItem(action: _exportIdentity),
                    child: Text(s.exportIdentity, style: style)),
                PopupMenuItem<_IdentitySelectorMenuItem>(
                    value: _IdentitySelectorMenuItem(
                        action: _confirmDeleteIdentity),
                    child: Text(s.deleteIdentity, style: style)),
                PopupMenuItem<_IdentitySelectorMenuItem>(
                    value: _IdentitySelectorMenuItem(action: _importAccount),
                    child: Text(s.importAccount, style: style)),
              ];
        },
      ),
    );
  }

  void _importIdentity() {
    ScanOrPasteIdentityDialog.show(
      context: context,
      onImport: _onImportIdentity,
    );
  }

  void _onImportIdentity(ParseOrchidIdentityOrAccountResult? result) async {
    if (result != null) {
      if (result.hasMultipleAccounts) {
        await _importMultipleAccounts(result.accounts ?? []);
      } else {
        await result.saveIfNeeded();
        _setSelectedIdentity(result.signer);
      }
      _refreshIndicatorKey.currentState?.show();
    }
  }

  Future<void> _importMultipleAccounts(List<Account> accounts) async {
    // Without this the dialog will not appear... why?
    await Future.delayed(millis(0));
    await AccountSelectorDialog.show(
      context: context,
      accounts: accounts,
      onSelectedAccounts: (accounts) async {
        log("XXX: onSelectedAccounts");
        await ParseOrchidIdentityOrAccountResult.saveAccountsIfNeeded(accounts);
        _setSelectedIdentity(accounts.first.signerKey);
      },
    );
  }

  void _importAccount() {
    // State used by the dialog
    Account? _accountToImport;

    final doImport = (BuildContext context) async {
      if (_accountToImport == null) {
        return;
      }
      await UserPreferencesVPN().ensureSaved(_accountToImport!);

      // Set the identity and refresh
      _setSelectedIdentity(_accountToImport!.signerKey);

      final account = _accountToImport;

      setState(() {
        _accountToImport = null;
      });
      // dismiss the dialog
      Navigator.pop(context);

      // trigger a refresh
      await _refreshIndicatorKey.currentState?.show();

      // Support onboarding by prodding the account finder if it exists
      // AccountFinder.shared?.refresh();
      if (await CircuitUtils.defaultCircuitIfNeededFrom(account)) {
        CircuitUtils.showDefaultCircuitCreatedDialog(context);
      }
    };

    AppDialogs.showAppDialog(
      context: context,
      showActions: false,
      contentPadding: EdgeInsets.zero,
      // This stateful builder allows this dialog to rebuild in response to setstate
      // on the _accountToImport in the parent.
      body: StatefulBuilder(builder: (context, setState) {
        return SizedBox(
          // Width here is effectively a max width and prevents dialog resizing
          width: 370,
          child: IntrinsicHeight(
            child: OrchidTitledPanel(
              highlight: false,
              opaque: true,
              titleText: s.importAccount,
              onDismiss: () {
                Navigator.pop(context);
              },
              body: Column(
                children: [
                  OrchidAccountEntry(
                    onAccountUpdate: (Account? account) {
                      setState(() {
                        log('XXX: onChange = $account');
                        _accountToImport = account;
                      });
                    },
                    onAccountsImport: (List<Account> accounts) async {
                      await _importMultipleAccounts(accounts);
                      Navigator.pop(context);
                    },
                    initialKeySelection: _selectedIdentity?.ref(),
                  ),
                  OrchidActionButton(
                    text: s.importAccount.toUpperCase(),
                    enabled: _accountToImport != null,
                    onPressed: () => doImport(context),
                  ).bottom(32),
                ],
              ).padx(24),
            ),
          ),
        );
      }),
    );
  }

  void _generateIdentity() async {
    var identity = StoredEthereumKey.generate();
    await UserPreferencesKeys().addKey(identity);
    _setSelectedIdentity(identity);
  }

  void _deleteIdentity(StoredEthereumKey identity) async {
    await UserPreferencesKeys().removeKey(identity.ref());
    // Remove accounts for this key.
    var matchingAccounts = UserPreferencesVPN().cachedDiscoveredAccounts.get();

    // var matching = matchingAccounts
    //     .where((account) => account.signerKeyRef == identity.ref());
    // log("XXX: delete identity removed ${matching.length} matching accounts");

    matchingAccounts
        ?.removeWhere((account) => account.signerKeyRef == identity.ref());

    UserPreferencesVPN().cachedDiscoveredAccounts.set(matchingAccounts);
    _setSelectedIdentity(_chooseDefaultIdentity(_identities ?? []));
  }

  // Import a signer key (identity)
  void _exportIdentity() async {
    var identity = _selectedIdentity;
    if (identity == null) {
      return;
    }
    var config = identity.toExportString();
    AccountManagerPageUtil.export(context, config);
  }

  // Delete the active identity after in-use check and user confirmation.
  void _confirmDeleteIdentity() async {
    var identity = _selectedIdentity;
    if (identity == null) {
      return;
    }

    // Check if the identity is currently used in an Orchid hop
    List<String> activeKeyUids = await OrchidHop.getInUseKeyUids();
    if (activeKeyUids.contains(identity.uid)) {
      await AppDialogs.showAppDialog(
          context: context,
          title: s.orchidAccountInUse,
          bodyText: s.thisOrchidAccountIsInUseAndCannotBeDeleted);
      return;
    }

    // TODO: Pull out all our commonly used tags into OrchidText
    var body = StyledText(
      style: OrchidText.body2.black,
      newLineAsBreaks: true,
      text: s.thisCannotBeUndoneToSaveThisIdentity,
      tags: {
        'bold': StyledTextTag(
          style: OrchidText.body2.black.bold,
        ),
        'save': StyledTextActionTag((text, attr) {
          Navigator.pushNamed(context, AppRoutes.manage_config);
        }, style: OrchidText.linkStyle),
      },
    );

    await AppDialogs.showConfirmationDialog(
      context: context,
      title: s.deleteThisOrchidIdentity,
      body: body,
      cancelText: s.cancel.toUpperCase(),
      //cancelColor: bodyStyle.color,
      actionText: s.delete.toUpperCase(),
      // Localize all caps version
      actionColor: Colors.red,
      commitAction: () {
        _deleteIdentity(identity);
      },
    );
  }

  Column _buildIdentityHeader() {
    return Column(
      children: [
        pady(12),
        if (_selectedIdentity != null)
          OrchidCircularIdenticon(address: _selectedIdentity!.address),
        pady(24),
        Text(s.orchidIdentity, style: OrchidText.body2),
        if (_selectedIdentity != null)
          Container(
            width: AppSize(context).widerThan(AppSize.iphone_12_pro_max)
                ? null
                : 238,
            child: Center(
              child: TapToCopyText(
                _selectedIdentity!.address.toString(),
                key: ValueKey(_selectedIdentity!.address.toString()),
                padding: EdgeInsets.only(top: 8, bottom: 8),
                style:
                    OrchidText.caption.copyWith(color: OrchidColors.tappable),
                onTap: (String text) async {
                  _copyAndShowOrchidAccountAddressWarning(
                      qrCodeText: text, showQRCode: false);
                },
                onLongPress: (String text) async {
                  _copyAndShowOrchidAccountAddressWarning(
                      qrCodeText: text, showQRCode: true);
                },
              ),
            ),
          )
        else
          pady(16)
      ],
    );
  }

  Future<void> _copyAndShowOrchidAccountAddressWarning(
      {required String qrCodeText, bool showQRCode = false}) async {
    await TapToCopyText.copyTextToClipboard(qrCodeText);
    var title = s.copiedOrchidIdentity;
    final bodyText = StyledText(
      style: OrchidText.body2,
      newLineAsBreaks: true,
      text: '<alarm/> <bold>' +
          s.thisIsNotAWalletAddress +
          '</bold>' +
          '  ' +
          s.doNotSendTokensToThisAddress +
          '\n\n' +
          s.yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork +
          '  ' +
          s.learnMoreAboutYourLinkorchidIdentitylink,
      tags: {
        'bold': StyledTextTag(
          style: OrchidText.body2.purpleBright.bold,
        ),
        'link': OrchidText.linkStyle.link(OrchidUrls.partsOfOrchidAccount),
        'alarm': StyledTextIconTag(Icons.warning_amber_rounded,
            color: OrchidColors.purple_bright)
      },
    );
    final qrCode = () => Container(
          width: 250,
          height: 250,
          child: Center(
            child: QrImage(
              data: qrCodeText,
              backgroundColor: Colors.white,
              version: QrVersions.auto,
              size: 250.0,
            ),
          ),
        );

    return AppDialogs.showAppDialog(
      context: context,
      title: title,
      body: showQRCode
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                bodyText,
                qrCode().top(24),
              ],
            )
          : bodyText,
    );
  }

  Widget _buildNoIdentitiesEmptyState() {
    return OrchidTitledPanel(
      highlight: false,
      titleText: s.orchidIdentity,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("You need an Orchid Identity to use the App. Create one, or import an identity or configuration.")
              .body2
              .center
              .padx(24)
              .top(32),
          OrchidActionButton(
            enabled: true,
            text: s.generateIdentity,
            onPressed: _generateIdentity,
          ).top(32),
          OrchidOutlineButton(
            text: s.importIdentity.toUpperCase(),
            onPressed: _importIdentity,
          ).top(16).bottom(40),
        ],
      ),
    ).padx(32).top(24);
  }

  Widget _buildNoAccountsEmptyState() {
    return _buildRefreshIndicator(
      OrchidTitledPanel(
        highlight: false,
        titleText: "Add an account",
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("If you funded an account on the Orchid DApp, scan or manually add below.")
                .body2
                .center
                .padx(24)
                .top(32),
            OrchidOutlineButton(
              text: "MANUALLY IMPORT ACOUNT",
              onPressed: _importAccount,
            ).top(32),
            OrchidOutlineButton(
              text: "SCAN FOR ACCOUNTS",
              onPressed: () async {
                await _refreshIndicatorKey.currentState?.show();
              },
              borderColor: Colors.transparent,
            ).top(16).bottom(40),
          ],
        ),
      ),
    ).padx(32).top(16);
  }

  //
  Widget _buildAccountListAnnotatedActive() {
    return StreamBuilder<Circuit>(
        stream: UserPreferencesVPN().circuit.stream(),
        builder: (context, snapshot) {
          Circuit? circuit = snapshot.data;
          Set<Account> activeAccounts = circuit?.activeOrchidAccounts ?? {};
          return _buildAccountList(activeAccounts);
        });
  }

  Widget _buildAccountList(Set<Account> activeAccounts) {
    var signerKey = _selectedIdentity;
    if (signerKey == null) {
      return Container();
    }
    List<AccountViewModel> accounts = (_accountStore?.accounts ?? {})
        // accounts may be for identity selection only, remove those
        // .where((a) => a.funder != null)
        .map((Account account) {
      return AccountViewModel(
          chain: Chains.chainFor(account.chainId),
          signerKey: signerKey,
          funder: account.funder,
          active: activeAccounts.contains(account),
          detail: _accountDetailStore.get(account));
    }).toList();

    // Support testing
    if (AccountMock.mockAccounts) {
      accounts = AccountManagerMock.accountViewModel;
    }

    // Sort by efficiency descending
    accounts.sort((AccountViewModel a, AccountViewModel b) {
      return -((a.detail.marketConditions?.efficiency ?? 0)
          .compareTo((b.detail.marketConditions?.efficiency ?? 0)));
    });

    Widget footer() {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 128),
        child: Align(
            child: Column(
          children: [
            Text(s.pullToRefresh, style: OrchidText.caption),
          ],
        )),
      );
    }

    var accountListView = accounts.isEmpty
        ? ListView(
            children: [pady(8), footer()],
          )
        : ListView.separated(
            // physics: const BouncingScrollPhysics( decelerationRate: ScrollDecelerationRate.normal),
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) =>
                Container(height: 24),
            key: PageStorageKey('account list view'),
            primary: true,
            itemCount: accounts.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == accounts.length) {
                return footer();
              }
              var account = accounts[index];
              return Container(
                key: Key(account.toString()),
                alignment: Alignment.center,
                child: _buildAccountCard(account, index),
              );
            });

    return _buildRefreshIndicator(accountListView);
  }

  RefreshIndicator _buildRefreshIndicator(Widget child) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      color: Colors.white,
      backgroundColor: OrchidColors.purple_ffb88dfc,
      displacement: 0,
      onRefresh: _doRefresh,
      child: child,
    );
  }

  Future<void> _doRefresh() async {
    // Refresh the account details
    _accountDetailStore.refresh();

    // Look for new accounts
    await _accountStore?.refresh(); // Return the load future

    // return _accountStore.refresh().then((value) async {
    //   final accounts = _accountStore.accounts;
    //   if (await CircuitUtils.defaultCircuitFromMostEfficientAccountIfNeeded(
    //       accounts)) {
    //     CircuitUtils.showDefaultCircuitCreatedDialog(context);
    //   }
    //   return null;
    // }); // Return the load future
  }

  Widget _buildAccountCard(AccountViewModel accountModel, int index) {
    return AccountCard(
      key: Key(accountModel.toString()),
      accountDetail: accountModel.detail,
      active: accountModel.active,
      initiallyExpanded: widget.openToAccount != null &&
          accountModel.detail.account == widget.openToAccount,
    );
  }

  Widget _buildAddFundsButton() {
    return StreamBuilder<PacTransaction?>(
        stream: PacTransaction.shared.stream(),
        builder: (context, snapshot) {
          var tx = snapshot.data;
          var enabled = _selectedIdentity != null && tx == null;
          return OrchidActionButton(
            enabled: enabled,
            text: s.addFunds,
            onPressed: _addFunds,
          );
        });
  }

  Future<void> _addFunds() async {
    var signerKey = _selectedIdentity;
    if (signerKey == null) {
      throw Exception('iap: no signer!');
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (BuildContext context) {
            return PurchasePage(
                signerKey: signerKey,
                cancellable: true,
                completion: () {
                  log('purchase complete');
                  CircuitUtils.findAccountsAndDefaultCircuitIfNeeded(context);
                });
          }),
    );
  }

  void _accountDetailChanged() {
    setState(() {}); // Trigger a UI refresh
  }

  @override
  void dispose() {
    _subs.dispose();
    if (_accountStore != null) {
      _accountStore!.removeListener(_accountsUpdated);
    }
    _accountDetailStore.dispose();
    super.dispose();
  }
}

class AccountManagerPageUtil {
  static Future<void> export(BuildContext context, String config) async {
    final s = context.s;
    var title = s.exportThisOrchidKey;
    // var bodyStyle = AppText.dialogBody.copyWith(fontSize: 15);
    var bodyStyle = OrchidText.body2;
    // var linkStyle = AppText.linkStyle.copyWith(fontSize: 15);
    var linkStyle = OrchidText.body2.copyWith(color: Colors.deepPurple);

    var body = StyledText(
      style: bodyStyle,
      newLineAsBreaks: true,
      text: s.aQrCodeAndTextForAllTheOrchidAccounts +
          '  ' +
          s.weRecommendBackingItUp +
          '\n\n' +
          s.importThisKeyOnAnotherDeviceToShareAllThe,
      tags: {
        'link': linkStyle.link(OrchidUrls.partsOfOrchidAccount),
      },
    );

    return AppDialogs.showAppDialog(
        context: context,
        title: title,
        body: ExportIdentityDialog(body: body, config: config));
  }
}

class _IdentitySelectorMenuItem {
  /// Either an identity...
  final StoredEthereumKey? identity;

  /// ...or an action with label
  final Function()? action;

  _IdentitySelectorMenuItem({this.identity, this.action}) {
    assert(identity != null || action != null);
  }

  bool get isIdentity {
    return identity != null;
  }

  String formatIdentity() {
    return identity?.address.toString().prefix(12) ?? '???';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _IdentitySelectorMenuItem &&
          runtimeType == other.runtimeType &&
          identity == other.identity &&
          action == other.action;

  @override
  int get hashCode => identity.hashCode ^ action.hashCode;
}
