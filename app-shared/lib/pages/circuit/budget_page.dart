import 'package:flutter/material.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'circuit_hop.dart';

class BudgetEditorPage extends HopEditor<OrchidHop> {
  BudgetEditorPage({@required editableHop})
      : super(editableHop: editableHop, mode: HopEditorMode.Edit);

  @override
  _BudgetEditorState createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<BudgetEditorPage> {
  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
      child: TitledPage(
        title: "Budget",
        child: SafeArea(
          child: Container(),
        ),
      ),
    );
  }
}

