// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/plain_text_box.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';

class OpenSourcePage extends StatefulWidget {
  @override
  _OpenSourcePageState createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  String _licenseText = "...";

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _licenseText = await OrchidDocs.openSourceLicenses();
    setState(() { });
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
