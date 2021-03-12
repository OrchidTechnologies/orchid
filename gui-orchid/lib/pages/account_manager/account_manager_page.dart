import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/circuit/orchid_hop_page.dart';
import 'package:orchid/pages/circuit/scan_paste_dialog.dart';
import 'package:orchid/pages/common/account_chart.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/pages/common/tap_copy_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';
import 'package:orchid/pages/purchase/purchase_status.dart';
import 'package:orchid/util/listenable_builder.dart';
import 'package:orchid/util/strings.dart';

import '../app_colors.dart';
import '../app_sizes.dart';
import '../app_text.dart';
import 'account_detail_poller.dart';
import 'account_model.dart';
import 'account_store.dart';
import 'account_view.dart';

class AccountManagerPage extends StatefulWidget {
  @override
  _AccountManagerPageState createState() => _AccountManagerPageState();
}

class _AccountManagerPageState extends State<AccountManagerPage> {
  var _accountStore = AccountStore();

  Map<Account, AccountDetailPoller> _accountDetailMap = {};

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _accountStore.load();
    PacTransaction.shared.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: _accountStore,
        builder: (context, snapshot) {
          return TitledPage(
            title: '',
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildIdentityHeader(),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildIdentitySelectorMenu(),
                            )),
                      ],
                    ),
                    pady(16),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: PurchaseStatus(),
                    ),
                    pady(8),
                    Divider(height: 1),
                    Expanded(child: _buildAccountList()),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildIdentitySelectorMenu() {
    return PopupMenuButton<IdentitySelectorMenuItem>(
      icon: Icon(Icons.settings, color: Colors.grey),
      initialValue: _accountStore.activeIdentity != null
          ? IdentitySelectorMenuItem(identity: _accountStore.activeIdentity)
          : null,
      onSelected: (IdentitySelectorMenuItem item) async {
        if (item.isIdentity) {
          _accountStore.setActiveIdentity(item.identity);
        } else {
          item.action();
        }
        AppDialogs.showConfigurationChangeSuccess(context, warnOnly: true);
      },
      itemBuilder: (BuildContext context) {
        var items = _accountStore.identities.map((StoredEthereumKey identity) {
          var item = IdentitySelectorMenuItem(identity: identity);
          return PopupMenuItem<IdentitySelectorMenuItem>(
            value: item,
            child: Text(item.formatIdentity()),
          );
        }).toList();

        // Add the import, export actions
        return items +
            [
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value: IdentitySelectorMenuItem(action: _newIdentity),
                  child: Text('New')),
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value: IdentitySelectorMenuItem(action: _importIdentity),
                  child: Text('Import')),
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value: IdentitySelectorMenuItem(action: _exportIdentity),
                  child: Text('Export')),
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value:
                      IdentitySelectorMenuItem(action: _confirmDeleteIdentity),
                  child: Text('Delete'))
            ];
      },
    );
  }

  void _importIdentity() {
    ScanOrPasteDialog.show(
      context: context,
      onImportAccount: (ParseOrchidAccountResult result) async {
        if (result.identity != null) {
          if (result.identity.isNew) {
            await UserPreferences().addKey(result.identity.signer);
            await _accountStore.load();
          }
          _accountStore.setActiveIdentity(result.identity.signer);
        } else {
          if (result.account.newKeys.isNotEmpty) {
            await UserPreferences().addKeys(result.account.newKeys);
            await _accountStore.load();
          }
          _accountStore.setActiveIdentity(result.account.account.signer);
        }
      },
    );
  }

  void _newIdentity() async {
    var secret = Crypto.generateKeyPair().private;
    var key = StoredEthereumKey(
      imported: false,
      time: DateTime.now(),
      uid: Crypto.uuid(),
      private: secret,
    );
    await _accountStore.addIdentity(key);
  }

  void _exportIdentity() async {
    var identity = _accountStore.activeIdentity;
    if (identity == null) {
      return;
    }
    var config = 'account={ secret: "${identity.formatSecretFixed()}" }';
    var title = 'My Orchid Identity' + ':';
    OrchidHopPage.showShareConfigStringDialog(
        context: context, title: title, config: config);
  }

  // Delete the active identity after in-use check and user confirmation.
  void _confirmDeleteIdentity() async {
    var identity = _accountStore.activeIdentity;
    if (identity == null) {
      return;
    }

    List<String> activeKeyUids = await OrchidVPNConfigV0.getInUseKeyUids();

    if (activeKeyUids.contains(identity.uid)) {
      await AppDialogs.showAppDialog(
          context: context,
          title: "Signer in use",
          bodyText: "This signer key is in use and cannot be deleted.");
      return;
    }

    await AppDialogs.showConfirmationDialog(
      context: context,
      title: "Delete Identity?",
      body: "This cannot be undone.  Please back up keys before deleting them.",
      cancelText: s.cancel,
      actionText: s.delete,
      commitAction: () {
        _doDeleteIdentity(identity);
      },
    );
  }

  void _doDeleteIdentity(StoredEthereumKey identity) async {
    await _accountStore.removeIdentity(identity);
  }

  Column _buildIdentityHeader() {
    return Column(
      children: [
        Text("Orchid Address", style: AppText.dialogTitle),
        if (_accountStore.activeIdentity != null) _buildIdenticon(),
        if (_accountStore.activeIdentity != null)
          Container(
            width:
                AppSize(context).widerThan(AppSize.iphone_12_max) ? null : 250,
            child: Center(
              child: TapToCopyText(
                  _accountStore.activeIdentity.address.toString(),
                  key:
                      ValueKey(_accountStore.activeIdentity.address.toString()),
                  padding: EdgeInsets.zero,
                  style: AppText.dialogTitle),
            ),
          )
      ]..spaced(8),
    );
  }

  Widget _buildIdenticon() {
    String svg =
        Jdenticon.toSvg(_accountStore.activeIdentity.address.toString());
    return SvgPicture.string(
      svg,
      fit: BoxFit.contain,
      height: 64,
      width: 64,
    );
  }

  Widget _buildAccountList() {
    var signerKey = _accountStore.activeIdentity;
    var activeAccount = _accountStore.activeAccount;

    var accounts = _accountStore.accounts
        // accounts may be for identity selection only, remove those
        .where((a) => a.funder != null)
        .map((Account account) {
      return AccountModel(
          chain: Chains.chainFor(account.chainId),
          signerKey: signerKey,
          funder: account.funder,
          active: account == activeAccount,
          detail: _accountDetail(account));
    }).toList();

    // Sort
    accounts.sort((AccountModel a, AccountModel b) {
      // put active at the top (descending)
      return a.active ? -1 : 1;
    });

    Widget footer() {
      if (OrchidPlatform.isNotApple) {
        return Container();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Align(
            child: Container(
          width: 190,
          child: _buildAddFundsButton(),
        )),
      );
    }

    var child = accounts.isEmpty
        ? ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: Text(
                        _accountStore.activeIdentity != null
                            ? "Searching for accounts..."
                            : "",
                        style: AppText.noteStyle)),
              ),
              footer()
            ],
          )
        : ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                Divider(height: 1),
            key: PageStorageKey('account list view'),
            primary: true,
            itemCount: accounts.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == accounts.length) {
                return footer();
              }
              var account = accounts[index];
              return Theme(
                data: ThemeData(accentColor: AppColors.purple_3),
                child: Container(
                  alignment: Alignment.center,
                  child: IntrinsicHeight(
                    child: _buildAccountTile(account, index),
                  ),
                ),
              );
            });

    return RefreshIndicator(
      displacement: 20,
      onRefresh: () async {
        _accountDetailMap.clear();
        _accountStore.load();
        // _accountDetailMap.forEach((key, value) { value.refresh(); });
      },
      child: child,
    );
  }

  ListTile _buildAccountTile(AccountModel account, int index) {
    var style = TextStyle(fontSize: 15);
    return ListTile(
      tileColor: account.active ? Colors.green.shade50 : null,
      onTap: () {
        _showAccount(account);
      },
      key: Key(index.toString()),
      title: Row(
        children: [
          Container(width: 24, height: 24, child: account.chain.icon),
          padx(4),
          Container(
              width: 18,
              height: 18,
              child: FittedBox(
                child: account.detail.marketConditions != null
                    ? AccountChart.circularEfficiencyChart(
                        account.detail.marketConditions?.efficiency)
                    : Container(),
              )),
          padx(8),
          Flexible(
            flex: 1,
            child: Text(
              account.funder.toString(),
              style: AppText.logStyle.copyWith(fontSize: style.fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          padx(12),
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  LabeledCurrencyValue(
                      label: "Balance:", style: style, value: account.balance),
                  padx(8),
                  LabeledCurrencyValue(
                      label: "Deposit:", style: style, value: account.deposit),
                ],
              ),
            ),
          )
        ],
      ),
      subtitle: account.active
          ? Padding(
              padding: const EdgeInsets.only(left: 54.0, top: 2),
              child: Text(
                "Active",
                textAlign: TextAlign.left,
              ),
            )
          : null,
    );
  }

  Widget _buildAddFundsButton() {
    return StreamBuilder<PacTransaction>(
        stream: PacTransaction.shared.stream(),
        builder: (context, snapshot) {
          var enabled =
              _accountStore.activeIdentity != null && snapshot.data == null;
          return RoundedRectButton(
            text: "Add Credit",
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: enabled ? _addFunds : null,
          );
        });
  }

  void _setActiveAccount(AccountModel account) {
    _accountStore.setActiveAccount(account.detail.account); // a bit convoluted
    AppDialogs.showConfigurationChangeSuccess(context, warnOnly: true);
  }

  void _showAccount(AccountModel account) async {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return AccountView(account: account, setActiveAccount: _setActiveAccount);
    }));
  }

  void _addFunds() async {
    var signer = _accountStore.activeIdentity?.address;
    if (signer == null) {
      throw Exception("iap: no signer!");
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (BuildContext context) {
            return PurchasePage(
                signer: signer,
                completion: () {
                  log("purchase complete");
                });
          }),
    );
  }

  // Return a cached or new account detail poller for the account.
  AccountDetailPoller _accountDetail(Account account) {
    var signer =
        StoredEthereumKey.find(_accountStore.identities, account.identityUid);
    var poller = _accountDetailMap[account];
    if (poller == null) {
      poller =
          AccountDetailPoller(account: account, resolvedSigner: signer.address);
      poller.addListener(_accountDetailChanged);
      poller.start();
      _accountDetailMap[account] = poller;
    }
    return poller;
  }

  void _accountDetailChanged() {
    setState(() {}); // Trigger a UI refresh
  }

  @override
  void dispose() {
    _accountDetailMap.forEach((key, value) {
      value.removeListener(_accountDetailChanged);
    });
    super.dispose();
  }

  S get s {
    return S.of(context);
  }
}

class IdentitySelectorMenuItem {
  /// Either an identity...
  final StoredEthereumKey identity;

  /// ...or an action with label
  final Function() action;

  IdentitySelectorMenuItem({this.identity, this.action});

  bool get isIdentity {
    return identity != null;
  }

  String formatIdentity() {
    return identity?.address?.toString()?.prefix(12) ?? "ERROR";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentitySelectorMenuItem &&
          runtimeType == other.runtimeType &&
          identity == other.identity &&
          action == other.action;

  @override
  int get hashCode => identity.hashCode ^ action.hashCode;
}
