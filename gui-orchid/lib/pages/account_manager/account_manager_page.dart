import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/pages/common/account_chart.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/pages/common/tap_copy_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/util/listenable_builder.dart';
import 'package:orchid/util/units.dart';

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
  double _usdCredit = 0;
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
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildIdentityHeader(),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildIdentityPopupMenu(),
                            )),
                      ],
                    ),
                    Divider(),
                    _buildCreditsView(_usdCredit),
                    Divider(),
                    Expanded(child: _buildAccountList()),
                    //FloatingAddButton(onPressed: _addKey),
                  ]..spaced(8),
                ),
              ),
            ),
          );
        });
  }

  Widget _buildIdentityPopupMenu() {
    var formatIdentity = (StoredEthereumKey identity) {
      if (identity == null) return null;
      return identity.address.toString().prefix(12);
    };

    return PopupMenuButton<StoredEthereumKey>(
      icon: Icon(Icons.settings, color: Colors.grey),
      initialValue: _accountStore.activeIdentity,
      onSelected: (StoredEthereumKey identity) async {
        _accountStore.setActiveIdentity(identity);
      },
      itemBuilder: (BuildContext context) {
        return _accountStore.identities.map((identity) {
          return PopupMenuItem<StoredEthereumKey>(
            value: identity,
            child: Text(formatIdentity(identity)),
          );
        }).toList();
      },
    );
  }

  Column _buildIdentityHeader() {
    return Column(
      children: [
        Text("Signer Address", style: AppText.dialogTitle),
        if (_accountStore.activeIdentity != null) _buildIdenticon(),
        if (_accountStore.activeIdentity != null)
          Container(
            width:
                AppSize(context).widerThan(AppSize.iphone_12_max) ? null : 250,
            child: Center(
              child: TapToCopyText(
                  _accountStore.activeIdentity.address.toString(),
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
    log("XXX: before sort accounts = $accounts");
    accounts.sort((AccountModel a, AccountModel b) {
      // put active at the top (descending)
      return a.active ? -1 : 1;
    });
    log("XXX: after sort accounts = $accounts");

    return RefreshIndicator(
      displacement: 20,
      onRefresh: () async {
        _accountStore.load();
      },
      child: accounts.isEmpty
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
                )
              ],
            )
          : ListView.separated(
              separatorBuilder: (BuildContext context, int index) =>
                  Divider(height: 1),
              key: PageStorageKey('account list view'),
              primary: true,
              itemCount: accounts.length,
              itemBuilder: (BuildContext context, int index) {
                var account = accounts[index];
                return Theme(
                  data: ThemeData(accentColor: AppColors.purple_3),
                  child: Container(
                    //height: 70,
                    alignment: Alignment.center,
                    //decoration: BoxDecoration(color: Colors.transparent),
                    child: IntrinsicHeight(
                      child: _buildAccountTile(account, index),
                    ),
                  ),
                );
              }),
    );
  }

  ListTile _buildAccountTile(AccountModel account, int index) {
    // log("XXX: build account tile for account: $account");

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
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Active",
                textAlign: TextAlign.left,
              ),
            )
          : null,
    );
  }

  Widget _buildCreditsView(double credit) {
    var style = TextStyle(fontSize: 17);
    var creditString = '\$' + (credit != null ? formatCurrency(credit) : "...");
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("VPN Credits:", style: style),
      padx(4),
      Text(creditString, style: style.copyWith(fontWeight: FontWeight.bold)),
      padx(36),
      RoundedRectButton(
        text: "Add Funds",
        icon: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: _addFunds,
      ),
    ]);
  }

  void _setActiveAccount(AccountModel account) {
    log("XXX: set active account: $account");
    _accountStore.setActiveAccount(account.detail.account); // a bit convoluted
    OrchidAPI().updateConfiguration();
    AppDialogs.showConfigurationChangeSuccess(context, warnOnly: true);
  }

  void _showAccount(AccountModel account) async {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return AccountView(account: account, setActiveAccount: _setActiveAccount);
    }));
  }

  // TODO: Replace with new purchase page
  void _addFunds() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return TitledPage(
                  title: 'Add Funds', cancellable: true, child: Container());
              // return PurchasePage(onAddFlowComplete: (CircuitHop result) {  },);
            }));
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
}
