import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/pages/common/plain_text_box.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class HelpOverviewPage extends StatefulWidget {
  @override
  _HelpOverviewPageState createState() => _HelpOverviewPageState();
}

class _HelpOverviewPageState extends State<HelpOverviewPage> {
  final String title = "Orchid Overview";
  String _helpText = "";

  @override
  void initState() {
    super.initState();

    OrchidDocs.helpOverview().then((text) {
      setState(() {
        _helpText = text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: title, child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 24),
            PlainTextBox(text: _helpText),
          ],
        ),
      ),
    );
  }
}
