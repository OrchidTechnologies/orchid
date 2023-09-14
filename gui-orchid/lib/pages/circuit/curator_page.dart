import 'package:flutter/material.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
import 'hop_editor.dart';
import 'package:orchid/util/localization.dart';

class CuratorEditorPage extends HopEditor<OrchidHop> {
  CuratorEditorPage({required editableHop})
      : super(editableHop: editableHop, mode: HopEditorMode.Edit);

  @override
  _CuratorEditorState createState() => _CuratorEditorState();
}

class _CuratorEditorState extends State<CuratorEditorPage> {
  var _curatorField = TextEditingController();

  @override
  void initState() {
    super.initState();
    OrchidHop? hop = widget.editableHop.value?.hop as OrchidHop;
    _curatorField.text = hop.curator ?? '';
    _curatorField.addListener(_updateHop);
  }

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
      child: TitledPage(
        title: s.curation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[_buildCuratorField()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuratorField() {
    return Row(
      children: <Widget>[
        Container(
          width: 90,
          child: Text(s.curator + ":").title,
        ),
        Expanded(
            child: OrchidTextField(
          hintText: OrchidHop.appDefaultCurator,
          controller: _curatorField,
        ))
      ],
    );
  }

  void _updateHop() {
    widget.editableHop.update(OrchidHop.from(
        widget.editableHop.value?.hop as OrchidHop,
        curator: _curatorField.text));
    setState(() {});
  }
}
