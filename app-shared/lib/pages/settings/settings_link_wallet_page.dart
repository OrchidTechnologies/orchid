import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLinkWalletPage extends StatefulWidget {
  @override
  _SettingsLinkWalletPageState createState() => _SettingsLinkWalletPageState();
}

class _SettingsLinkWalletPageState extends State<SettingsLinkWalletPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Link Wallet", child: buildPage(context));
  }

  final api = OrchidAPI();

  /// If non-null represents the currently saved wallet.
  OrchidWalletPublic _walletPublic;

  /// If non-null represents transient storage of a user-entered private key.
  /// This field is cleared after the data is passed to the API for storage.
  OrchidWalletPrivate _walletPrivate;

  var _textController = TextEditingController();
  var _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {}); // trigger UI update on focus change
    });
    api.getWallet().then((OrchidWalletPublic wallet) {
      setState(() {
        this._walletPublic = wallet;
      });
    });
  }

  // This arrangement with the layout builder, scroll view, constrained box, and intrinsic height
  // allows us to fill the screen normally while remaining in a list view.  The scroll view is
  // necessary to accommodate the keyboard when the text field has focus.
  // https://docs.flutter.io/flutter/widgets/SingleChildScrollView-class.html
  @override
  Widget buildPage(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: <Widget>[
                  Spacer(flex: 1),

                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, right: 40, top: 1, bottom: 18),
                    child: AppText.header(text: "Link an external wallet"),
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 40, right: 40, bottom: 15),
                      child: AppText.body(
                        text:
                            "You need to link Orchid to an Ethereum wallet in order to use the Alpha. Enter or scan a private key for the wallet you want to use to pay for bandwidth.",
                      )),

                  Padding(
                    padding: EdgeInsets.only(left: 40, right: 40, bottom: 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            style: AppText.bodyStyle
                                .copyWith(fontWeight: FontWeight.w700),
                            text:
                                "Make sure your wallet is on testnet and using test tokens while Orchid is in Alpha. If you do not have an Ethereum wallet on testnet, you can set one up ",
                          ),
                          LinkTextSpan(
                            text: "here.",
                            style: AppText.bodyStyle.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal_3),
                            url: 'https://orchid.com',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Info button
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: FlatButton(
                      child: Icon(
                        Icons.info_outline,
                        color: AppColors.text_header_purple,
                      ),
                      onPressed: () {
                        launch('https://orchid.com', forceSafariVC: false);
                      },
                    ),
                  ),

                  buildWalletKeyEntry(context),

                  Spacer(flex: 3),
                  SizedBox(height: 16),

                  // Add button
                  Container(
                    margin: EdgeInsets.only(bottom: 62),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16))),
                      child: AppText.body(
                          text: "ADD",
                          color: AppColors.text_light,
                          letterSpacing: 1.25,
                          lineHeight: 1.14),
                      color: AppColors.purple,
                      onPressed: _walletPrivate != null ? _addButtonPressed : null,
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create the text field with QR scanning option for the private key.
  Widget buildWalletKeyEntry(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Color(0xfffbfbfe),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Color(0xffd5d7e2), width: 2.0)),
        height: 58,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  obscureText: false,
                  controller: _textController,
                  autocorrect: false,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: (_walletPublic == null || _focusNode.hasFocus)
                          ? "Paste private key here"
                          : "Linked Wallet: ${_walletPublic.id}",
                      hintStyle: AppText.hintStyle),
                  onChanged: _keyTextChanged,
                  focusNode: _focusNode,
                ),
              ),
            ),
            Container(
                margin: EdgeInsets.only(right: 13.0),
                child: Image(image: AssetImage("assets/images/scan.png")))
          ],
        ));
  }

  // TODO:
  bool _keyTextValid(String text) {
    return text != null && text.length > 3;
  }

  bool _keyTextChanged(String text) {
    var valid = _keyTextValid(text);
    _walletPrivate = valid ? OrchidWalletPrivate(privateKey: text) : null;
  }

  void _addButtonPressed() {
    assert(_walletPrivate != null);

    // dismiss the keyboard if present
    FocusScope.of(context).requestFocus(new FocusNode());

    // Save the wallet
    var public = OrchidWalletPublic(_walletPrivate.privateKey.substring(0, 3) + "xxx...");
    var wallet = OrchidWallet(public: public, private: _walletPrivate);
    api.setWallet(wallet).then((bool success) {

      // Update the UI
      setState(() {
        _textController.clear();
        _walletPrivate = null;
        if (success) {
          _walletPublic = public;
        }
      });
      if (success) {
        Dialogs.showWalletLinkedDialog(context);
      } else {
        Dialogs.showWalletLinkFailedDialog(context);
      }
    });
  }
}
