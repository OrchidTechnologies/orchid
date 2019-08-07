import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/pages/common/plain_text_box.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class PrivacyPage extends StatefulWidget {
  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final String title = "Privacy Policy";
  String _privacyText = "";

  @override
  void initState() {
    super.initState();

    OrchidDocs.privacyPolicy().then((text) {
      setState(() {
        _privacyText = text;
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
            Text(
              title,
              textAlign: TextAlign.left,
            ),
            PlainTextBox(text: _privacyText),
          ],
        ),
      ),
    );
  }
}
