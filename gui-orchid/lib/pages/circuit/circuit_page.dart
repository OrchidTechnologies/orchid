import 'dart:async';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/account/account_detail_store.dart';
import 'package:orchid/pages/circuit/config_change_dialogs.dart';
import 'package:orchid/vpn/model/openvpn_hop.dart';
import 'package:orchid/vpn/model/wireguard_hop.dart';
import 'circuit_utils.dart';
import 'hop_editor.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';
import 'package:orchid/util/collections.dart';
import 'package:orchid/util/localization.dart';

/// The multi-hop circuit builder page.
class CircuitPage extends StatefulWidget {
  // Note: This performs a behavior like the iOSContacts App create flow for the
  // Note: add hop action, revealing the already pushed hop editor upon completing
  // Note: the add flow.
  static var iOSContactsStyleAddHopBehavior = false;

  CircuitPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CircuitPageState();
  }
}

class CircuitPageState extends State<CircuitPage>
    with TickerProviderStateMixin {
  List<StreamSubscription> _rxSubs = [];
  List<UniqueHop> _hops = [];

  bool _dialogInProgress = false; // ?

  late AccountDetailStore _accountDetailStore;

  @override
  void initState() {
    super.initState();
    _accountDetailStore =
        AccountDetailStore(onAccountDetailChanged: _accountDetailChanged);
    initStateAsync();
  }

  void initStateAsync() async {
    OrchidAPI().circuitConfigurationChanged.listen((_) {
      _updateCircuit();
    });
    // Update the UI on connection status changes
    _rxSubs.add(OrchidAPI().vpnRoutingStatus.listen(_connectionStateChanged));
  }

  void _updateCircuit() async {
    var circuit = UserPreferencesVPN().circuit.get()!; // never null
    if (mounted) {
      setState(() {
        var keyBase = DateTime.now().millisecondsSinceEpoch;
        // Wrap the hops with a locally unique id for the UI
        _hops = UniqueHop.wrap(circuit.hops, keyBase);
      });

      // Set the correct animation states for the connection status
      // Note: We cannot properly do this until we know if we have hops!
      log('init state, setting initial connection state');
      _connectionStateChanged(OrchidAPI().vpnRoutingStatus.value,
          animated: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: s.circuitBuilder,
      // decoration: BoxDecoration(),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Flexible is needed for scrolling and shrink behavior
        Flexible(child: _buildHopList()),
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: _buildFooter(),
        ),
      ],
    );
  }

  Widget _buildHopList() {
    // Wrap the children for the reorderable list view
    var children = _hops.mapIndexed((uniqueHop, i) {
      return ReorderableDelayedDragStartListener(
        key: Key(uniqueHop.key.toString()),
        index: i,
        child: Center(child: _buildDismissableHopTile(uniqueHop, i)),
      );
    }).toList();

    return Theme(
      data: ThemeData(canvasColor: Colors.transparent),
      child: ReorderableListView(
          // Sizes to the min height in the body column
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          // Turn off drag handles and specify long press to reorder using the
          // drag start listener below
          buildDefaultDragHandles: false,
          padding: EdgeInsets.symmetric(horizontal: 32),
          header: Column(
            children: <Widget>[
              _buildStatusTile(),
              pady(64),
            ],
          ),
          children: children,
          onReorder: _onReorder),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: <Widget>[
        pady(8),
        _buildNewHopTile(),
      ],
    );
  }

  Widget _buildNewHopTile() {
    return GestureDetector(
      onTap: _addHop,
      child: DottedBorder(
          color: Color(0xffb88dfc),
          strokeWidth: 2.0,
          dashPattern: [8, 10],
          radius: Radius.circular(10),
          borderType: BorderType.RRect,
          child: Container(
            width: 328,
            height: 72,
            child: Center(
              child: Text(s.addNewHop, style: OrchidText.button.tappable),
            ),
          )),
    );
  }

  Widget _buildStatusTile() {
    String text = s.orchidDisabled;
    Color color = Colors.redAccent.withOpacity(0.7);
    if (_connected()) {
      if (_hasHops()) {
        var num = _hops.length;
        text = s.numHopsConfigured(num);
        color = Colors.greenAccent.withOpacity(0.7);
      } else {
        text = s.trafficMonitoringOnly;
        color = Colors.yellowAccent.withOpacity(0.7);
      }
    }

    var status = OrchidAPI().vpnRoutingStatus.value;
    if (status == OrchidVPNRoutingState.VPNConnecting) {
      text = s.starting;
      color = Colors.yellowAccent.withOpacity(0.7);
    }
    if (status == OrchidVPNRoutingState.VPNConnected) {
      text = s.orchidConnecting;
      color = Colors.yellowAccent.withOpacity(0.7);
    }
    if (status == OrchidVPNRoutingState.VPNDisconnecting) {
      text = s.orchidDisconnecting;
      color = Colors.yellowAccent.withOpacity(0.7);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.fiber_manual_record, color: color, size: 18),
          padx(5),
          Text(text,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.white,
              )),
        ],
      ),
    );
  }

  Widget _buildDismissableHopTile(UniqueHop uniqueHop, int index) {
    bool confirmDismiss =
        uniqueHop.hop is OpenVPNHop || uniqueHop.hop is WireGuardHop;
    return Padding(
      key: Key(uniqueHop.key.toString()),
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Dismissible(
        key: Key(uniqueHop.key.toString()),
        background: buildDismissableBackground(context),
        confirmDismiss: confirmDismiss ? _confirmDeleteHop : null,
        onDismissed: (direction) {
          _deleteHop(uniqueHop);
        },
        child: _buildTappableHopTile(uniqueHop, index),
      ),
    );
  }

  static Container buildDismissableBackground(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              S.of(context)!.delete,
              style: TextStyle(color: Colors.white),
            ),
          )),
    );
  }

  Widget _buildTappableHopTile(UniqueHop uniqueHop, int index) {
    return GestureDetector(
      onTap: () {
        _viewHop(uniqueHop);
      },
      // Don't allow the cards to expand, etc.
      child: AbsorbPointer(
        child: _buildAnnotatedHopTile(uniqueHop, index),
      ),
    );
  }

  /// Add the e.g. entry, exit descriptions
  Widget _buildAnnotatedHopTile(UniqueHop uniqueHop, int index) {
    int count = _hops.length;
    var title = s.hop;
    if (count > 1 && index == 0) {
      title = s.entryHop;
    } else if (count > 1 && index == _hops.length - 1) {
      title = s.exitHop;
    }
    return Column(
      children: [
        Row(
          children: [
            padx(24),
            Text(title).body1,
          ],
        ),
        pady(8),
        _buildHopTile(uniqueHop),
      ],
    );
  }

  Widget _buildHopTile(UniqueHop uniqueHop) {
    switch (uniqueHop.hop.protocol) {
      case HopProtocol.Orchid:
        var hop = uniqueHop.hop as OrchidHop;
        var accountDetail = _accountDetailStore.get(hop.account);
        return AccountCard(
          accountDetail: accountDetail,
          minHeight: true,
        );
      case HopProtocol.OpenVPN:
      case HopProtocol.WireGuard:
        return _buildOtherHopTile(uniqueHop);
    }
  }

  // Note: We should integrate this into AccountCard
  Widget _buildOtherHopTile(UniqueHop hop) {
    Widget icon = Container();
    Widget text = Container();
    switch (hop.hop.protocol) {
      case HopProtocol.Orchid:
        break;
      case HopProtocol.OpenVPN:
        icon = SvgPicture.asset(OrchidAssetSvg.openvpn_path,
            width: 38, height: 38);
        text = Text(s.openVPNHop).title;
        break;
      case HopProtocol.WireGuard:
        icon = SvgPicture.asset(OrchidAssetSvg.wireguard_path,
            width: 40, height: 40);
        text = Text(s.wireguardHop).title;
        break;
    }
    // Match account card for now
    return SizedBox(
      width: 334,
      height: 74,
      child: OrchidPanel(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 40, child: icon),
            text,
            SizedBox(width: 40)
          ],
        ),
      )),
    );
  }

  ///
  /// Begin - Add / view hop logic
  ///

  void _addHop() async {
    CircuitUtils.addHop(context, onComplete: _addHopComplete);
  }

  // Local page state updates after hop addition.
  void _addHopComplete(UniqueHop uniqueHop) {
    // TODO: needed? Or does the global config change handle it?
    setState(() {
      _hops.add(uniqueHop);
    });

    // View the newly created hop:
    // Note: This performs a behavior like the iOS-Contacts App add flow,
    // Note: revealing the already pushed navigation state upon completing the
    // Note: add flow.  This non-animated push approximates this.
    if (CircuitPage.iOSContactsStyleAddHopBehavior) {
      _viewHop(uniqueHop, animated: false);
    }
  }

  void _saveCircuit() async {
    var circuit = Circuit(_hops.map((uniqueHop) => uniqueHop.hop).toList());
    UserPreferencesVPN().saveCircuit(circuit);
    _showConfigurationChangedDialog();
  }

  void _showConfigurationChangedDialog() async {
    if (_dialogInProgress) {
      return;
    }
    try {
      _dialogInProgress = true;
      await ConfigChangeDialogs.showConfigurationChangeSuccess(context,
          warnOnly: true);
    } finally {
      _dialogInProgress = false;
    }
  }

  // View a hop selected from the circuit list
  void _viewHop(UniqueHop uniqueHop, {bool animated = true}) async {
    EditableHop editableHop = EditableHop(uniqueHop);
    HopEditor editor = editableHop.editor();
    await editor.show(context, animated: animated);

    // TODO: avoid saving if the hop was not edited.
    // Save the hop if it was edited.
    var index = _hops.indexOf(uniqueHop);
    if (editableHop.value == null) {
      throw Exception("EditableHop.value should not be null");
    }
    setState(() {
      _hops.removeAt(index);
      _hops.insert(index, editableHop.value!);
    });
    _saveCircuit();
  }

  // Callback for swipe to delete
  Future<bool?> _confirmDeleteHop(dismissDirection) async {
    var result = await AppDialogs.showConfirmationDialog(
      context: context,
      title: s.confirmDelete,
      bodyText: s.deletingOpenVPNAndWireguardHopsWillLose,
    );
    return result;
  }

  // Callback for swipe to delete
  void _deleteHop(UniqueHop uniqueHop) async {
    var index = _hops.indexOf(uniqueHop);
    _hops.removeAt(index);
    setState(() {});
    _saveCircuit();
  }

  // Callback for drag to reorder
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final UniqueHop hop = _hops.removeAt(oldIndex);
      _hops.insert(newIndex, hop);
    });
    _saveCircuit();
  }

  ///
  /// Begin - VPN Connection Status Logic
  ///

  bool _connected() {
    var state = OrchidAPI().vpnRoutingStatus.value;
    switch (state) {
      case OrchidVPNRoutingState.VPNDisconnecting:
      case OrchidVPNRoutingState.VPNNotConnected:
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.VPNConnected:
        return false;
      case OrchidVPNRoutingState.OrchidConnected:
        return true;
    }
  }

  /// Called upon a change to Orchid connection state
  void _connectionStateChanged(OrchidVPNRoutingState state,
      {bool animated = true}) {
    if (mounted) {
      setState(() {});
    }
  }

  ///
  /// Begin - util
  ///

  bool _hasHops() {
    return _hops.length > 0;
  }

  void _accountDetailChanged() {
    if (mounted) {
      setState(() {}); // Trigger a UI refresh
    }
  }

  @override
  void dispose() {
    _accountDetailStore.dispose();
    _rxSubs.forEach((sub) {
      sub.cancel();
    });
    super.dispose();
  }
}
