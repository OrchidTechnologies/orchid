import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/keys/add_key_page.dart';
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
  StoredEthereumKeyRef _initialKeyRef;
  StoredEthereumKeyRef _selectedKeyRef;

  @override
  void initState() {
    super.initState();
    setState(() {
      OrchidHop hop = widget.editableHop.value?.hop;
      _funderField.text = hop?.funder;
      _selectedKeyRef = hop?.keyRef;
      _initialKeyRef = _selectedKeyRef;
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
                        key: ValueKey(_initialKeyRef.toString()),
                        enabled: widget.editable(),
                        initialSelection: _initialKeyRef,
                        onSelection: _keySelected),
                  )),

                  // Copy key button
                  Visibility(
                    visible: widget.viewOnly(),
                    child: RoundedRectRaisedButton(
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        text: "Copy",
                        onPressed: _onCopyButton),
                  ),

                  // Add key button
                  Visibility(
                    visible: widget.editable(),
                    child: _buidAddKeyButton(),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Widget _buidAddKeyButton() {
    return GestureDetector(
      onTap: _onCopyButton,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        width: 35,
        height: 35,
        child: Icon(Icons.add_circle_outline, color: Colors.white),
      ),
    );
  }*/
  Widget _buidAddKeyButton() {
    return Container(
      width: 30,
      child: FlatButton(
          padding: EdgeInsets.only(right: 5),
          child: Icon(Icons.add_circle_outline, color: Colors.grey),
          onPressed: _onAddKeyButton),
    );
  }

  void _keySelected(StoredEthereumKey key) {
    setState(() {
      _selectedKeyRef = key.ref();
    });
  }

  void _textFieldChanged() {
    setState(() {}); // Update validation
  }

  bool _keyRefValid() {
    return _selectedKeyRef != null;
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
            funder: Hex.removePrefix(_funderField.text),
            keyRef: _selectedKeyRef));
  }

  /// Copy the log data to the clipboard
  void _onCopyButton() async {
    StoredEthereumKey key = await _selectedKeyRef.get();
    Clipboard.setData(ClipboardData(text: key.keys().address));
  }

  void _onAddKeyButton() async {
    var route = MaterialPageRoute<StoredEthereumKey>(
        builder: (context) => AddKeyPage(), fullscreenDialog: true);
    StoredEthereumKey key = await Navigator.push(context, route);

    // User cancelled
    if (key == null) {
      return;
    }

    // Save the new key
    var keys = await UserPreferences().getKeys() ?? [];
    keys.add(key);
    await UserPreferences().setKeys(keys);

    // Select the new key in the list
    setState(() {
      _initialKeyRef = key.ref(); // rebuild the dropdown
      _selectedKeyRef = _initialKeyRef;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _funderField.removeListener(_textFieldChanged);
  }
}
