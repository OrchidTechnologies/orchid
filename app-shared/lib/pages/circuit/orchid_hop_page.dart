import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_colors.dart';
import '../app_text.dart';
import 'circuit_hop.dart';
import 'key_selection.dart';

// TODO: This was originally designed to allow partial (invalid) configuration
// TODO: to be observed and saved in edit mode.  If no longer needed we can
// TODO: remove that abstraction.
/// Create / edit / view an Orchid Hop
class OrchidHopPage extends HopEditor<OrchidHop> {
  OrchidHopPage({@required editableHop, mode = HopEditorMode.View})
      : super(editableHop: editableHop, mode: mode);

  @override
  _OrchidHopPageState createState() => _OrchidHopPageState();
}

class _OrchidHopPageState extends State<OrchidHopPage> {
  var _funderField = TextEditingController();

  // Reference to the selected StoredEthereumKey
  StoredEthereumKeyRef _keyRef;

  @override
  void initState() {
    super.initState();
    setState(() {
      OrchidHop hop = widget.editableHop.value?.hop;
      _funderField.text = hop?.funder;
      _keyRef = hop?.keyRef;
    });
    _funderField.addListener(_textFieldChanged);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _updateHop();
  }

  @override
  Widget build(BuildContext context) {
    var isValid = _funderValid() && _keyRefValid();
    return TitledPage(
      title: "Orchid Hop",
      actions: widget.mode == HopEditorMode.Create
          ? [widget.buildSaveButton(context, isValid: isValid)]
          : [],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              pady(16),
              Row(
                children: <Widget>[
                  Text("Funder:",
                      style: AppText.textLabelStyle.copyWith(
                          fontSize: 20,
                          color: _funderValid()
                              ? AppColors.neutral_1
                              : AppColors.neutral_3)),
                  Expanded(
                      child: AppTextField(
                    controller: _funderField,
                    enabled: widget.editable(),
                  ))
                ],
              ),
              pady(16),
              Row(
                children: <Widget>[
                  Text("Signer:",
                      style: AppText.textLabelStyle.copyWith(
                          fontSize: 20,
                          color: _keyRefValid()
                              ? AppColors.neutral_1
                              : AppColors.neutral_3)),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 16),
                    child: KeySelection(
                        enabled: widget.editable(),
                        initialSelection: _keyRef,
                        onSelection: _keySelected),
                  )),

                  // Key Copy
                  Visibility(
                    visible: widget.viewOnly(),
                    child: RoundedRectRaisedButton(
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        text: "Copy",
                        onPressed: _onCopyButton),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _keySelected(StoredEthereumKey key) {
    setState(() {
      _keyRef = key.ref();
    });
  }

  void _textFieldChanged() {
    setState(() {}); // Update validation
  }

  bool _keyRefValid() {
    return _keyRef != null;
  }

  bool _funderValid() {
    try {
      EthereumAddress.parse(_funderField.text);
      return true;
    } catch (err) {
      print(err);
      return false;
    }
  }

  void _updateHop() {
    if (!widget.editable()) {
      return;
    }
    widget.editableHop.value = UniqueHop(
        key: widget.editableHop.value?.key ??
            DateTime.now().millisecondsSinceEpoch,
        hop: OrchidHop(
            funder: Hex.removePrefix(_funderField.text), keyRef: _keyRef));
  }

  /// Copy the log data to the clipboard
  void _onCopyButton() {
    Clipboard.setData(ClipboardData(text: _funderField.text));
  }

  @override
  void dispose() {
    super.dispose();
    _funderField.removeListener(_textFieldChanged);
  }
}
