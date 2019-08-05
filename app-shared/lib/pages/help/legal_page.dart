import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accommodate_keyboard.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';

class LegalPage extends StatefulWidget {
  @override
  _LegalPageState createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Legal", child: buildPage(context));
  }

  var privacyText = TextSpan(
    children: <TextSpan>[
      LinkTextSpan(
        text: "Orchid Privacy Policy and Contact",
        style: AppText.linkStyle,
        url: 'https://orchid.com/privacy',
      ),
    ],
  );

  String licenseText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

  Widget buildPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AccommodateKeyboard(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 24),

              // Privacy text
              RichText(textAlign: TextAlign.left, text: privacyText),
              SizedBox(height: 24),

              Text("Open Source Licenses", textAlign: TextAlign.left,),
              Padding(
                padding: const EdgeInsets.only(
                    left: 8, right: 8, top: 16, bottom: 32),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    reverse: false,
                    child: Text(
                      licenseText,
                      textAlign: TextAlign.left,
                      style: AppText.logStyle,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    border:
                    Border.all(width: 2.0, color: AppColors.neutral_5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
