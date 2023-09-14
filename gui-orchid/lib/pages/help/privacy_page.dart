import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/common/plain_text_box.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/util/localization.dart';

class PrivacyPage extends StatefulWidget {
  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
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
    String title = s.privacyPolicy;
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
            PlainTextBox(text: _privacyText),
          ],
        ),
      ),
    );
  }
}
