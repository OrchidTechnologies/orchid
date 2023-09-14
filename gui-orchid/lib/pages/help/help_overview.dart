import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/scheduler.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:html/dom.dart' as dom;
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpOverviewPage extends StatefulWidget {
  @override
  _HelpOverviewPageState createState() => _HelpOverviewPageState();
}

class _HelpOverviewPageState extends State<HelpOverviewPage> {
  String? _helpText;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      OrchidDocs.helpOverview(context).then((text) {
        setState(() {
          _helpText = text;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: s.orchidOverview, child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    if (_helpText == null) {
      return Center(
          child: OrchidCircularProgressIndicator.smallIndeterminate());
    }
    return Theme(
      data: Theme.of(context).copyWith(
        // highlightColor: OrchidColors.tappable,
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.white.withOpacity(0.4)),
          // isAlwaysShown: true,
        ),
      ),
      child: SafeArea(
        // The HTML must be a direct child of the scrollview.
        child: SingleChildScrollView(
          child: html(_helpText!),
        ).padx(16),
      ),
    );
  }

  // flutter_hmtl supports a subset of html: https://pub.dev/packages/flutter_html
  Widget html(String html) {
    dom.Element doc = HtmlParser.parseHTML(html);

    // Add the index
    _generateIndex(doc);

    return Html.fromElement(
      documentElement: doc,
      onLinkTap: (url, context, attributes, element) {
        launch(url ?? '', forceSafariVC: false);
      },
      style: {
        'body': Style.fromTextStyle(OrchidText.body2),
        'a': Style.fromTextStyle(OrchidText.body2.linkStyle),
        'h1': Style.fromTextStyle(
            OrchidText.title.copyWith(fontSize: 24, height: 1.0)),
        'h2': Style.fromTextStyle(OrchidText.title.copyWith(height: 1.0)),
      },
    );
  }

  /// Add unique ids to each H2 element and generate an index for them at
  /// the location of the <help_index></help_index> tag.
  void _generateIndex(dom.Element doc) {
    try {
      List<dom.Element> h2s = doc.getElementsByTagName('h2');
      h2s.forEachIndexed((h2, i) {
        h2.id = i.toString();
      });
      var indexLocationEl = doc.getElementsByTagName('help_index').first;
      var content = dom.Element.tag('div');
      content.innerHtml = '<ul>' +
          h2s
              .mapIndexed((h2, i) => '<li><a href="#$i">${h2.text}</a></li>')
              .join() +
          '</ul>';

      indexLocationEl.parent?.insertBefore(content, indexLocationEl);
    } catch (err) {
      log("html error generating index: $err");
    }
  }
}
