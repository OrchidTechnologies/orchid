import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import '../../common/app_colors.dart';
import '../../common/app_text.dart';
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
          width: 80,
          child: Text(s.curator+":",
              style: AppText.textLabelStyle
                  .copyWith(fontSize: 20, color: AppColors.neutral_1)),
        ),
        Expanded(
            child: OrchidTextField(
          controller: _curatorField,
        ))
      ],
    );
  }

  void _updateHop() {
    widget.editableHop.update(OrchidHop.from(widget.editableHop.value?.hop,
        curator: _curatorField.text));
  }

  S get s {
    return S.of(context);
  }
}
