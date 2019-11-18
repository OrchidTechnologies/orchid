import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_text.dart';
import 'circuit_hop.dart';

class OrchidHopPage extends StatefulWidget {
  final OrchidHop initialState;

  OrchidHopPage({this.initialState});

  @override
  _OrchidHopPageState createState() => _OrchidHopPageState();
}

class _OrchidHopPageState extends State<OrchidHopPage> {
  // TODO: Validation logic
  var funderField = TextEditingController();
  var secretField = TextEditingController();

  @override
  void initState() {
    super.initState();
    funderField.text = widget.initialState?.funder;
    secretField.text = widget.initialState?.secret;
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
                  Expanded(child: AppTextField(controller: funderField))
                ],
              ),
              pady(16),
              Row(
                children: <Widget>[
                  Text("Secret:",
                      style: AppText.textLabelStyle.copyWith(fontSize: 20)),
                  Expanded(child: AppTextField(controller: secretField))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _backAction() {
    Navigator.pop(
        context,
        UniqueHop(
            key: DateTime.now().millisecondsSinceEpoch,
            hop:
                OrchidHop(funder: funderField.text, secret: secretField.text)));
  }
}
