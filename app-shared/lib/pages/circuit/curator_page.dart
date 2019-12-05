import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_colors.dart';
import '../app_text.dart';
import 'hop_editor.dart';
import 'model/orchid_hop.dart';

class CuratorEditorPage extends HopEditor<OrchidHop> {
  CuratorEditorPage({@required editableHop})
      : super(editableHop: editableHop, mode: HopEditorMode.Edit);

  @override
  _CuratorEditorState createState() => _CuratorEditorState();
}

class _CuratorEditorState extends State<CuratorEditorPage> {
  var _curatorField = TextEditingController();

  @override
  void initState() {
    super.initState();
    OrchidHop hop = widget.editableHop.value?.hop;
    _curatorField.text = hop?.curator;
    _curatorField.addListener(_updateHop);
  }

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
      child: TitledPage(
        title: "Curation",
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
          width: 75,
          child: Text("Curator:",
              style: AppText.textLabelStyle
                  .copyWith(fontSize: 20, color: AppColors.neutral_1)),
        ),
        Expanded(
            child: AppTextField(
          controller: _curatorField,
        ))
      ],
    );
  }

  void _updateHop() {
    widget.editableHop.update(OrchidHop.from(widget.editableHop.value?.hop,
        curator: _curatorField.text));
  }
}
