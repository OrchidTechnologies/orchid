import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_text.dart';
import 'circuit_hop.dart';
import 'key_selection.dart';

class OrchidHopPage extends StatefulWidget {
  final OrchidHop initialState;

  OrchidHopPage({this.initialState});

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
      _funderField.text = widget.initialState?.funder;
      _keyRef = widget.initialState?.keyRef;
    });
    print("hop editor: initial keyref = $_keyRef");
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      backAction: _backAction,
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
      print("setting key ref to: ${key.ref()}");
      _keyRef = key.ref();
    });
  }

  void _backAction() {
    //
    if (_keyRef == null ||
        _funderField.text == null ||
        _funderField.text == "") {
      return null;
    }
    Navigator.pop(
        context,
        UniqueHop(
            key: DateTime.now().millisecondsSinceEpoch,
            hop: OrchidHop(funder: _funderField.text, keyRef: _keyRef)));
  }
}
