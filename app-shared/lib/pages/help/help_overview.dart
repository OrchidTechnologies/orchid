import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/pages/common/plain_text_box.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';

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
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[html(_helpText)],
            ),
          ),
        ),
      ),
    );
  }

  // flutter_hmtl supports a subset of html: https://pub.dev/packages/flutter_html
  Widget html(String html) {
    return Html(
      data: html,
      defaultTextStyle: TextStyle(fontSize: 16.0),
      linkStyle: const TextStyle(
        color: Colors.deepPurple,
      ),
      onLinkTap: (url) {
        launch(url, forceSafariVC: false);
      },
      onImageTap: (src) {},
      // This is our css :)
      customTextStyle: (dom.Node node, TextStyle baseStyle) {
        if (node is dom.Element) {
          switch (node.localName) {
            case "h2":
              return baseStyle.merge(TextStyle(fontSize: 20));
          }
        }
        return baseStyle;
      },
    );
  }
}
