import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_docs.dart';
import 'package:orchid/common/plain_text_box.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';

class OpenSourcePage extends StatefulWidget {
  @override
  _OpenSourcePageState createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  String _licenseText = "\nLoading...";

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _licenseText = await OrchidDocs.openSourceLicenses();
    _licenseText += '\n' + await OrchidDocs.flutterLicenseRegistryText();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String title = s.openSourceLicenses;
    return TitledPage(
      title: title,
      child: buildPage(context),
      constrainWidth: false,
    );
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: PlainTextBox(text: _licenseText).top(24).padx(16),
    );
  }
}
