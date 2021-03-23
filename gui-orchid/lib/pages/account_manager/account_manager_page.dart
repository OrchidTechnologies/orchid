import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_urls.dart';
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
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/tap_copy_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';
import 'package:orchid/pages/purchase/purchase_status.dart';
import 'package:orchid/util/listenable_builder.dart';
import 'package:orchid/util/strings.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
                  child: Text(s.newWord)),
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value: IdentitySelectorMenuItem(action: _importIdentity),
                  child: Text(s.import)),
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value: IdentitySelectorMenuItem(action: _exportIdentity),
                  child: Text(s.export)),
              PopupMenuItem<IdentitySelectorMenuItem>(
                  value:
                      IdentitySelectorMenuItem(action: _confirmDeleteIdentity),
                  child: Text(s.delete))
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
    var key = StoredEthereumKey.generate();
    await _accountStore.addIdentity(key);
  }

  void _exportIdentity() async {
    var identity = _accountStore.activeIdentity;
    if (identity == null) {
      return;
    }
    var config = 'account={ secret: "${identity.formatSecretFixed()}" }';
    var title = s.exportThisOrchidKey;
    var bodyStyle = AppText.dialogBody.copyWith(fontSize: 15);
    var linkStyle = AppText.linkStyle.copyWith(fontSize: 15);

    var body = RichText(
        text: TextSpan(children: [
      TextSpan(
          text: s.aQrCodeAndTextForAllTheOrchidAccounts + s.weRecommend + ' ',
          style: bodyStyle),
      LinkTextSpan(
        text: s.backingItUp + '.',
        style: linkStyle,
        url: OrchidUrls.partsOfOrchidAccount,
      ),
      TextSpan(
          text: '\n\n' + s.importThisKeyOnAnotherDeviceToShareAllThe,
          style: bodyStyle)
    ]));

    return AppDialogs.showAppDialog(
        context: context,
        title: title,
        body: Container(
          padding: EdgeInsets.all(8),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              body,
              pady(16),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: config));
                },
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        QrImage(
                          data: config,
                          version: QrVersions.auto,
                          size: 180.0,
                        ),
                        pady(8),
                        Container(
                          width: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.copy,
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                              Icon(
                                Icons.download_sharp,
                                color: Colors.deepPurple,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
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
          title: s.orchidAccountInUse,
          bodyText: s.thisOrchidAccountIsInUseAndCannotBeDeleted);
      return;
    }

    var bodyStyle = AppText.dialogBody; //.copyWith(fontSize: 15);
    var body = RichText(
        text: TextSpan(children: [
      TextSpan(
        text: identity.address.toString().prefix(24) + '\n\n',
        style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: s.thisCannotBeUndone +
            " " +
            s.deletingThisOrchidKeyCanCauseFundsInTheAssociated +
            " ",
        style: bodyStyle,
      ),
      AppText.buildLearnMoreLinkTextSpan(context),
    ]));

    await AppDialogs.showConfirmationDialog(
      context: context,
      title: s.deleteThisOrchidKey,
      body: body,
      cancelText: s.cancel,
      //cancelColor: bodyStyle.color,
      actionText: s.delete,
      // Localize all caps version
      actionColor: Colors.red,
      commitAction: () {
        _deleteIdentity(identity);
      },
    );
  }

  void _deleteIdentity(StoredEthereumKey identity) async {
    await _accountStore.deleteIdentity(identity);
  }

  Column _buildIdentityHeader() {
    return Column(
      children: [
        Text(s.orchidAddress, style: AppText.dialogTitle),
        if (_accountStore.activeIdentity != null)
          OrchidIdenticon(
              value: _accountStore.activeIdentity.address.toString()),
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
        padding: const EdgeInsets.only(top: 16),
        child: Align(
            child: Column(
          children: [
            Text(s.pullToRefresh,
                style: AppText.noteStyle.copyWith(fontStyle: FontStyle.italic)),
            pady(16),
            Container(
              width: 190,
              child: _buildAddFundsButton(),
            ),
          ],
        )),
      );
    }

    var child = accounts.isEmpty
        ? ListView(
            children: [pady(8), footer()],
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
      displacement: 0,
      onRefresh: () async {
        // Refresh the account details
        _accountDetailMap.forEach((key, value) {
          value.refresh();
        });

        // Look for new accounts
        return _accountStore.load(); // Return the load future
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
                      label: s.balance + ':',
                      style: style,
                      value: account.balance),
                  padx(8),
                  LabeledCurrencyValue(
                      label: s.deposit + ':',
                      style: style,
                      value: account.deposit),
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
                s.active,
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
          var tx = snapshot.data;
          var enabled = _accountStore.activeIdentity != null && tx == null;
          return RoundedRectButton(
            text: s.addCredit,
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
    var signerKey = _accountStore.activeIdentity;
    if (signerKey == null) {
      throw Exception("iap: no signer!");
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (BuildContext context) {
            return PurchasePage(
                signerKey: signerKey,
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

  void _disposeAccountDetailMap() {
    _accountDetailMap.forEach((key, value) {
      value.removeListener(_accountDetailChanged);
      value.dispose();
    });
  }

  @override
  void dispose() {
    _disposeAccountDetailMap();
    super.dispose();
  }

  S get s {
    return S.of(context);
  }
}

class OrchidIdenticon extends StatelessWidget {
  final String value;
  final double size;

  const OrchidIdenticon({
    Key key,
    @required this.value,
    this.size = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String svg = Jdenticon.toSvg(value);
    return SvgPicture.string(svg,
        fit: BoxFit.contain, height: size, width: size);
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
    return identity?.address?.toString()?.prefix(12) ?? '???';
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
