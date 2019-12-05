
import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_buttons.dart';

import 'add_hop_page.dart';
import 'model/circuit_hop.dart';

enum HopEditorMode { Create, Edit, View }

class EditableHop extends ValueNotifier<UniqueHop> {
  EditableHop(UniqueHop value) : super(value);

  EditableHop.empty() : super(null);

  void update(CircuitHop hop) {
    value = UniqueHop.from(value, hop: hop);
  }
}

class HopEditor<T extends CircuitHop> extends StatefulWidget {
  final EditableHop editableHop;
  final AddFlowCompletion onAddFlowComplete;

  // In create mode the editor offers a "save" button that pops the view and
  // returns the value on the context.  If the user navigates back without
  // saving the context result will be null.
  final HopEditorMode mode;

  HopEditor(
      {@required this.editableHop,
        @required this.mode,
        this.onAddFlowComplete});

  Widget buildSaveButton(BuildContext context, {bool isValid = true}) {
    return SaveActionButton(
        isValid: isValid,
        onPressed: () {
          this.onAddFlowComplete(this.editableHop.value.hop);
        });
  }

  bool editable() {
    return mode != HopEditorMode.View;
  }

  bool readOnly() {
    return !editable();
  }

  @override
  Widget build(BuildContext context) {
    throw Exception("implement in subclass");
  }

  @override
  State<StatefulWidget> createState() {
    throw Exception("implement in subclass");
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

  UniqueHop({@required this.key, @required this.hop});
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
