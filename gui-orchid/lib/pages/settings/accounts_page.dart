import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/circuit/circuit_page.dart';
import 'package:orchid/pages/circuit/hop_editor.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/circuit/orchid_hop_page.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/generated/l10n.dart';

import '../app_colors.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key key}) : super(key: key);

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<UniqueHop> _recentlyDeleted = [];
  List<OrphanedKeyAccount> _orphanedPacAccounts = [];

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _recentlyDeleted = await _getRecentlyDeletedHops();
    setState(() {});
    _findOrphanedPACs();
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      decoration: BoxDecoration(color: Colors.transparent),
      title: s.deletedHops,
      child: buildPage(context),
      lightTheme: true,
    );
  }

  Widget buildPage(BuildContext context) {
    List<Widget> list = [];
    if (_recentlyDeleted.isEmpty && _orphanedPacAccounts.isEmpty) {
      list.add(Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Text(
          s.noRecentlyDeletedHops,
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ));
    } else {
      //list.add(titleTile(s.recentlyDeleted));
      list.add(pady(16));
      list.add(_buildInstructions());
      list.add(pady(32));
      list.addAll((_recentlyDeleted ?? []).map((hop) {
        return _buildInactiveHopTile(hop);
      }).toList());
      if (_orphanedPacAccounts.isNotEmpty)
        list.add(Center(
            child: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 24),
          child: Text("Deleted PACs"),
        )));
      list.addAll((_orphanedPacAccounts ?? []).map((oa) {
        return _buildOrphanedAccountHopTile(oa);
      }).toList());
    }
    return ListView(children: list);
  }

  Widget titleTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      child: Text(
        text,
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Dismissible _buildInactiveHopTile(UniqueHop uniqueHop) {
    return Dismissible(
      key: Key(uniqueHop.key.toString()),
      background: CircuitPageState.buildDismissableBackground(context),
      confirmDismiss: _confirmDeleteHop,
      onDismissed: (direction) {
        _deleteHop(uniqueHop);
      },
      child: _buildHopTile(uniqueHop, activeHop: false),
    );
  }

  Dismissible _buildOrphanedAccountHopTile(OrphanedKeyAccount account) {
    OrchidHop hop = OrchidHop(
        funder: account.funder,
        curator: account.curator,
        keyRef: account.keyRef);
    UniqueHop uniqueHop =
        UniqueHop(hop: hop, key: account.keyRef.keyUid.hashCode);
    return Dismissible(
      key: Key(account.keyRef.toString()),
      background: CircuitPageState.buildDismissableBackground(context),
      confirmDismiss: _confirmDeleteHop,
      onDismissed: (direction) {
        _deleteOrphanedAcount(account);
      },
      child: _buildHopTile(uniqueHop, activeHop: false),
    );
  }

  void _deleteOrphanedAcount(OrphanedKeyAccount account) {
    log("account: delete orphaned account: ${account.keyRef}");
    UserPreferences().removeKey(account.keyRef);
    _findOrphanedPACs();
  }

  Widget _buildHopTile(UniqueHop uniqueHop, {bool activeHop = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: CircuitPageState.buildHopTile(
          context: context,
          onTap: () {
            _viewHop(uniqueHop);
          },
          uniqueHop: uniqueHop,
          bgColor: activeHop
              ? AppColors.purple_3.withOpacity(0.8)
              : Colors.grey[500],
          showAlertBadge: false),
    );
  }

  void _viewHop(UniqueHop uniqueHop, {bool animated = true}) async {
    EditableHop editableHop = EditableHop(uniqueHop);
    HopEditor editor = editableHop.editor();
    //  Turn off all editable features such as curation.
    if (editor is OrchidHopPage) {
      editor.disabled = true;
    }
    await editor.show(context, animated: animated);
  }

  Future<bool> _confirmDeleteHop(dismissDirection) async {
    var result = await Dialogs.showConfirmationDialog(
      context: context,
      title: s.confirmDelete,
      body: s.deletingThisHopWillRemoveItsConfiguredOrPurchasedAccount +
          "  " +
          s.ifYouPlanToReuseTheAccountLaterYouShould,
    );
    return result;
  }

  // Callback for swipe to delete
  void _deleteHop(UniqueHop uniqueHop) async {
    var index = _recentlyDeleted.indexOf(uniqueHop);
    setState(() {
      _recentlyDeleted.removeAt(index);
    });
    UserPreferences().setRecentlyDeleted(
      Hops(_recentlyDeleted.map((h) {
        return h.hop;
      }).toList()),
    );

    // Also remove the keys now
    bool orphanKeys = (await OrchidVPNConfig.getUserConfigJS())
        .evalBoolDefault('orphanKeys', false);
    if (uniqueHop.hop is OrchidHop && !orphanKeys) {
      var hop = uniqueHop.hop as OrchidHop;
      UserPreferences().removeKey(hop.keyRef);
    }

    initStateAsync();
  }

  // e.g. recently deleted
  Future<List<UniqueHop>> _getRecentlyDeletedHops() async {
    var recentlyDeletedHops = await UserPreferences().getRecentlyDeleted();
    var keyBase = DateTime.now().millisecondsSinceEpoch;
    var hops = recentlyDeletedHops.hops.where((hop) {
      return hop is OrchidHop;
    }).toList();
    return UniqueHop.wrap(hops, keyBase);
  }

  S get s {
    return S.of(context);
  }

  void _findOrphanedPACs() async {
    _orphanedPacAccounts = [];

    // Get the active hop keys
    var activeHops = (await UserPreferences().getCircuit()).hops;
    List<OrchidHop> activeOrchidHops =
        activeHops.where((h) => h is OrchidHop).cast<OrchidHop>().toList();
    List<StoredEthereumKeyRef> activeKeys = activeOrchidHops.map((h) {
      return h.keyRef;
    }).toList();
    List<String> activeKeyUuids = activeKeys.map((e) => e.keyUid).toList();
    log("account: activeKeyUuids = $activeKeyUuids");

    // Get recently deleted hop list keys
    List<OrchidHop> deletedOrchidHops = _recentlyDeleted
        .map((h) => h.hop)
        .where((h) => h is OrchidHop)
        .cast<OrchidHop>()
        .toList();
    log("account: deleted orchid hops = $deletedOrchidHops");
    List<StoredEthereumKeyRef> deletedKeys = deletedOrchidHops.map((h) {
      return h.keyRef;
    }).toList();
    log("account: deleted orchid keys = $deletedKeys");
    List<String> deletedKeyUuids = deletedKeys.map((e) => e.keyUid).toList();
    log("account: deletedKeyUuids = $deletedKeyUuids");

    // Find the orphans
    List<StoredEthereumKey> allKeys = await UserPreferences().getKeys();
    List<StoredEthereumKey> orphanedKeys = allKeys
        .where((k) =>
            !activeKeyUuids.contains(k.uid) && !deletedKeyUuids.contains(k.uid))
        .toList();
    log("account: orphaned keys = $orphanedKeys");

    var curator = await UserPreferences().getDefaultCurator() ??
        OrchidHop.appDefaultCurator;

    // Determine which of these were PACs
    var orchidPacFunder =
        EthereumAddress.from('0x6dd46c5f9f19ab8790f6249322f58028a3185087');
    _orphanedPacAccounts = [];
    for (var key in orphanedKeys) {
      var signer = EthereumAddress.from(key.keys().address);
      try {
        var pot = await OrchidEthereum.getLotteryPot(orchidPacFunder, signer);
        if (pot.balance.value <= 0) {
          log("account: zero balance found for keys: [$orchidPacFunder, $signer]");
          continue;
        }
        log("account: found orphaned PAC with non-zero balance: [$orchidPacFunder, $signer]");
        setState(() {
          _orphanedPacAccounts
              .add(OrphanedKeyAccount(orchidPacFunder, key.ref(), curator));
          log("_orphaned pac accounts len = ${_orphanedPacAccounts.length}");
        });
      } catch (err) {
        log("account: Error checking pot.");
      }
    }
    setState(() {});
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32),
      child: Text(
          "To restore a deleted hop:" +
              "\n\n" +
              "1. Click the hop below then click ‘Share Orchid Account’ and hit ‘Copy’." +
              "\n" +
              "2. Return to the ‘Manage Profile’ screen, click ‘New Hop’ then ‘Link Orchid Account’ and ‘Paste’." +
              "\n\n" +
              "To permanently delete a hop from the list below, swipe left on it.",
          style: TextStyle(fontStyle: FontStyle.italic)),
    );
  }
}

class OrphanedKeyAccount {
  EthereumAddress funder;
  StoredEthereumKeyRef keyRef;
  String curator;

  OrphanedKeyAccount(this.funder, this.keyRef, this.curator);
}
