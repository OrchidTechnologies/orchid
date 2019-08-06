import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_docs.dart';
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

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 24),

              // Privacy text
              RichText(textAlign: TextAlign.left, text: privacyText),
              SizedBox(height: 24),

              Text("Open Source Licenses", textAlign: TextAlign.left,),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 16, bottom: 32),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      reverse: false,
                      child: Text(
                        _licenseText,
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
              ),

              SizedBox(height: 8)
            ],
          ),
        ),
      ),
    );
  }
}
