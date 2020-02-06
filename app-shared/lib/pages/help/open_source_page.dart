import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/plain_text_box.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class OpenSourcePage extends StatefulWidget {
  @override
  _OpenSourcePageState createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  String _licenseText = "";

  @override
  void initState() {
    super.initState();

    OrchidDocs.openSourceLicenses().then((text) {
      setState(() {
        _licenseText = text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = s.openSourceLicenses;
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
            PlainTextBox(text: _licenseText),
          ],
        ),
      ),
    );
  }

  S get s {
    return S.of(context);
  }
}
