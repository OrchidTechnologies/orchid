import 'package:flutter/material.dart';
import 'package:orchid/common/app_transitions.dart';
import 'package:orchid/pages/circuit/wireguard_hop_page.dart';
import 'package:orchid/common/app_buttons.dart';
import 'add_hop_page.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';
import 'openvpn_hop_page.dart';
import 'orchid_hop_page.dart';

enum HopEditorMode { Create, Edit, View }

class EditableHop extends ValueNotifier<UniqueHop?> {
  EditableHop(UniqueHop value) : super(value);

  EditableHop.empty() : super(null);

  void update(CircuitHop hop) {
    value = UniqueHop.from(value, hop: hop);
  }

  /// Create a new editor instance for this editable hop
  HopEditor editor() {
    HopEditor editor;
    switch (value?.hop.protocol) {
      case HopProtocol.Orchid:
        editor = OrchidHopPage(editableHop: this, mode: HopEditorMode.View);
        break;
      case HopProtocol.OpenVPN:
        editor = OpenVPNHopPage(editableHop: this, mode: HopEditorMode.Edit);
        break;
      case HopProtocol.WireGuard:
        editor = WireGuardHopPage(editableHop: this, mode: HopEditorMode.Edit);
        break;
      case null:
        throw Exception("EditableHop null");
    }
    return editor;
  }
}

class HopEditor<T extends CircuitHop> extends StatefulWidget {
  final EditableHop editableHop;
  final AddFlowCompletion? onAddFlowComplete;

  // In create mode the editor offers a "save" button that pops the view and
  // returns the value on the context.  If the user navigates back without
  // saving the context result will be null.
  final HopEditorMode mode;

  HopEditor(
      {required this.editableHop, required this.mode, this.onAddFlowComplete});

  Widget buildSaveButton(
      BuildContext context, AddFlowCompletion? onAddFlowComplete,
      {bool isValid = true}) {
    return SaveActionButton(
        isValid: isValid,
        onPressed: () {
          if (onAddFlowComplete != null) {
            onAddFlowComplete(this.editableHop.value?.hop);
          }
        });
  }

  bool editable() {
    return mode != HopEditorMode.View;
  }

  bool readOnly() {
    return !editable();
  }

  bool get create {
    return mode == HopEditorMode.Create;
  }

  Widget build(BuildContext context) {
    throw Exception("implement in subclass");
  }

  @override
  State<StatefulWidget> createState() {
    throw Exception("implement in subclass");
  }

  Future<void> show(BuildContext context, {bool animated = true}) async {
    var route = animated
        ? MaterialPageRoute(builder: (context) => this)
        : NoAnimationMaterialPageRoute(builder: (context) => this);
    await Navigator.push(context, route);
  }
}

/*
switch (hop.protocol) {
  case Protocol.Orchid:
    return UniqueHop<OrchidHop>(key: key, hop: hop);
  case Protocol.OpenVPN:
    return UniqueHop<OpenVPNHop>(key: key, hop: hop);
  default:
    throw Exception();
}
...

class UniqueHop<T extends CircuitHop> {
  final int key;
  final T hop;

  UniqueHop({required this.key, required this.hop});
}

class EditableHop<T extends CircuitHop> extends ValueNotifier<UniqueHop<T>> {
  EditableHop(UniqueHop<T> value) : super(value);
  EditableHop.empty() : super(null);
}

abstract class HopEditor<T extends CircuitHop> {
  final EditableHop<T> editableHop;
  HopEditor(this.editableHop);
}

*/
