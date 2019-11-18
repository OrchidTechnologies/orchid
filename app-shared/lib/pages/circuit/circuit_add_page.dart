import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_text.dart';
import 'hop.dart';

class CircuitAddPage extends StatefulWidget {
  final String initialFunder;
  final String initialSecret;

  CircuitAddPage({this.initialFunder, this.initialSecret});

  @override
  _CircuitAddPageState createState() => _CircuitAddPageState();
}

class _CircuitAddPageState extends State<CircuitAddPage> {
  // TODO: Validation logic
  var funderField = TextEditingController();
  var secretField = TextEditingController();


  @override
  void initState() {
    super.initState();
    funderField.text = widget.initialFunder;
    secretField.text = widget.initialSecret;
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
    var hop = Hop(funder: funderField.text, secret: secretField.text);
    Navigator.pop(context,
        UniqueHop(key: DateTime.now().millisecondsSinceEpoch, hop: hop));
  }
}
