import 'package:orchid/chat/scripting/code_viewer/script_code_box.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Code field',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = <String>[
      "dart|monokai-sublime",
      "python|atom-one-dark",
      "cpp|an-old-hope",
      "java|a11y-dark",
      "javascript|vs",
    ];
    const exampleCode = "x: int = 42;";
    List<Widget> children = preset.map((e) {
      final parts = e.split('|');
      print(parts);
      final box = UserScriptEditor(
        language: parts[0],
        theme: parts[1],
        initialScript: exampleCode,
        onScriptChanged: (script) { },
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: box,
      );
    }).toList();
    final page = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(children: children),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      appBar: AppBar(
        backgroundColor: const Color(0xff23241f),
        title: const Text("CodeField demo"),
        // title: Text("Recursive Fibonacci"),
        centerTitle: false,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              // primary: Colors.white,
            ),
            icon: const Icon(FontAwesomeIcons.github),
            onPressed: () =>
                _launchInBrowser("https://github.com/BertrandBev/code_field"),
            label: const Text("GITHUB"),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SingleChildScrollView(child: page),
      // body: CodeEditor5(),
    );
  }
}