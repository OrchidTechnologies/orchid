import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/instructions_view.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_text.dart';

class AddKeyPage extends StatefulWidget {
  @override
  _AddKeyPageState createState() => _AddKeyPageState();
}

class _AddKeyPageState extends State<AddKeyPage> {
  var _secretController = TextEditingController();
  BigInt _secret;

  @override
  void initState() {
    super.initState();
    _secretController.addListener(_onSecretChange);
  }

  void _onSecretChange() {
    try {
      var text = _secretController.text;
      if (text.toLowerCase().startsWith('0x')) {
        text = text.substring(2);
      }
      var bigInt = BigInt.parse(text, radix: 16);
      //  TODO: check this validation
      if (bigInt > BigInt.from(0) &&
          bigInt < ((BigInt.from(1) << 256) - BigInt.from(1))) {
        _secret = bigInt;
      } else {
        _secret = null;
      }
    } catch (err) {
      _secret = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "Create New Key",
      cancellable: true,
      child: TapClearsFocus(
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.basicGradient),
          child: Column(
            children: <Widget>[
              // Generate key
              pady(32),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Generate Key",
                        style: AppText.textLabelStyle.copyWith(fontSize: 18))),
              ),

              RoundedRectRaisedButton(
                  text: " GENERATE ", onPressed: _generateKey),

              // Import key
              pady(32),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Import Key",
                        style: AppText.textLabelStyle.copyWith(fontSize: 18))),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 0, bottom: 24),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                    autocorrect: false,
                    autofocus: false,
                    style: AppText.logStyle.copyWith(color: AppColors.grey_2),
                    controller: _secretController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Paste private key hex...",
                      hintStyle: AppText.textHintStyle.copyWith(
                          color: Colors.grey, fontStyle: FontStyle.italic),
                      border: InputBorder.none,
                    ),
                  ),
                  // TODO: This is used elsewhere, factor out
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(width: 2.0, color: AppColors.neutral_5),
                  ),
                ),
              ),
              _buildImportButton(),

              // Instructions
              Expanded(
                child: InstructionsView(
                  image: Image.asset("assets/images/howToken.png"),
                  title: "Create a key",
                  body:
                      "To ensure private browsing, you’ll need to link each new hop to a different funding source. Generate or import a new signer key here to link your hop to your funding source. This is a sentence describing what happens when you generate a signer key (need input).",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    bool isValid = _secret != null;
    return RoundedRectRaisedButton(
        text: " IMPORT ", onPressed: isValid ? _importKey : null);
  }

  void _importKey() {
    var key = StoredEthereumKey(
        time: DateTime.now(), imported: true, private: _secret);
    Navigator.pop(context, key);
  }

  void _generateKey() {
    var keyPair = Crypto.generateKeyPair();
    var key = StoredEthereumKey(
        time: DateTime.now(), imported: false, private: keyPair.private);
    Navigator.pop(context, key);
  }

  @override
  void dispose() {
    super.dispose();
    _secretController.removeListener(_onSecretChange);
  }
}
