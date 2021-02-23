import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../app_text.dart';

class KeyGenPage extends StatefulWidget {
  @override
  _KeyGenPageState createState() => _KeyGenPageState();
}

class _KeyGenPageState extends State<KeyGenPage> {
  EthereumKeyPair keyPair;
  bool revealPrivateKey = false;

  @override
  Widget build(BuildContext context) {
    return TitledPage(
        title: "Ethereum Key Generator", child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    var monoStyle = AppText.textEntryStyle.copyWith(fontSize: 18.0, fontFamily: 'Roboto Mono');
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          pady(16.0),
          Text(
            "Generate a new Ethererum public account and private key pair."
            "  Keys are not stored here and will be lost when you leave this page unless you retain them."
            "  Handle your private key with care as any party with access to the key has complete control of the account.\n",
            style: AppText.textHintStyle.copyWith(fontStyle: FontStyle.italic),
          ),

          pady(16.0),

          Visibility(
            visible: this.keyPair != null,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Public Key
                  Text(
                    "Account:",
                    style: AppText.textLabelStyle
                        .copyWith(fontSize: 20.0, color: Colors.black),
                  ),
                  pady(8),
                  SelectableText(
                    keyPair?.addressString ?? "",
                    style: monoStyle,
                  ),

                  pady(16),
                  GestureDetector(
                    onTap: _copyAccount,
                    child: Text(
                      "Tap to copy",
                      textAlign: TextAlign.center,
                      style: AppText.dialogButton.copyWith(
                          color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),

                  // Private Key
                  pady(32),
                  Text(
                    "Private:",
                    style: AppText.textLabelStyle
                        .copyWith(fontSize: 20.0, color: Colors.black),
                  ),
                  pady(8),
                  Visibility(
                    visible: revealPrivateKey,
                    child: SelectableText(
                      keyPair?.private.toString() ?? "",
                      style: monoStyle,
                    ),
                    replacement: Text(
                      "****************************************************************",
                      style: monoStyle,
                    ),
                  ),

                  pady(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      GestureDetector(
                        onTap:(){
                          setState(() {
                            this.revealPrivateKey = !this.revealPrivateKey;
                          });
                        },
                        child: Text(
                          "Tap to Reveal",
                          textAlign: TextAlign.center,
                          style: AppText.dialogButton.copyWith(
                              color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyPrivate,
                        child: Text(
                          "Tap to copy",
                          textAlign: TextAlign.center,
                          style: AppText.dialogButton.copyWith(
                              color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),

          Spacer(flex: 4),

          // Send button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Container(
                  width: 250,
                  height: 50,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: AppText.body(
                        text: "Generate Keypair",
                        fontSize: 18.0,
                        color: AppColors.text_light,
                        letterSpacing: 1.25,
                        lineHeight: 1.14),
                    color: AppColors.purple_3,
                    onPressed: _generate,
                  ),
                ),
              ),
            ),
          ),
          pady(32.0),
        ],
      ),
    );
  }

  void _generate() {
    var keyPair = Crypto.generateKeyPair();
    setState(() {
      this.revealPrivateKey = false;
      this.keyPair = keyPair;
    });
  }

  void _copyAccount() async {
    Clipboard.setData(ClipboardData(text: keyPair.addressString));
  }
  void _copyPrivate() async {
    Clipboard.setData(ClipboardData(text: keyPair.private.toString()));
  }
}
