import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_text.dart';
import 'circuit_hop.dart';
import 'key_selection.dart';

class OrchidHopPage extends StatefulWidget implements HopEditor<OrchidHop> {
  @override
  final EditableHop editableHop;

  OrchidHopPage({@required this.editableHop});

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
    _funderField.addListener(_updateHop);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _updateHop();
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "Orchid Hop",
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              pady(16),
              Row(
                children: <Widget>[
                  Text("Funder:",
                      style: AppText.textLabelStyle.copyWith(fontSize: 20)),
                  Expanded(child: AppTextField(controller: _funderField))
                ],
              ),
              pady(16),
              Row(
                children: <Widget>[
                  Text("Secret:",
                      style: AppText.textLabelStyle.copyWith(fontSize: 20)),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 16),
                    child: KeySelection(
                        initialSelection: _keyRef, onSelection: _keySelected),
                  ))
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

  void _updateHop() {
    widget.editableHop.value = UniqueHop(
        key: widget.editableHop.value?.key ?? DateTime.now().millisecondsSinceEpoch,
        hop: OrchidHop(funder: _funderField.text, keyRef: _keyRef));
  }

  @override
  void dispose() {
    super.dispose();
    _funderField.removeListener(_updateHop);
  }

}
