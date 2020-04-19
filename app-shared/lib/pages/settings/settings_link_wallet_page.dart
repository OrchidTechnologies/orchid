import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accommodate_keyboard.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/settings/wallet_key_entry.dart';
import 'package:url_launcher/url_launcher.dart';

/// The link wallet settings page
class SettingsLinkWalletPage extends StatefulWidget {
  @override
  _SettingsLinkWalletPageState createState() => _SettingsLinkWalletPageState();
}

class _SettingsLinkWalletPageState extends State<SettingsLinkWalletPage> {
  WalletKeyEntryController _walletKeyEntryController =
      WalletKeyEntryController();

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Link Wallet", child: buildPage(context));
  }

  @override
  Widget buildPage(BuildContext context) {
    return AccommodateKeyboard(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Spacer(flex: 1),
            SizedBox(height: 8),

            Padding(
              padding: EdgeInsets.only(left: 40, right: 40, top: 1, bottom: 18),
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
                      style:
                          AppText.bodyStyle.copyWith(fontWeight: FontWeight.w700),
                      text:
                          "Make sure your wallet is on testnet and using test tokens while Orchid is in Alpha. If you do not have an Ethereum wallet on testnet, you can set one up ",
                    ),
                    LinkTextSpan(
                      text: "here.",
                      style: AppText.linkStyle,
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

            WalletKeyEntry(controller: _walletKeyEntryController),
            Spacer(flex: 3),
            SizedBox(height: 16),

            // Add button
            Container(
              margin: EdgeInsets.only(bottom: 42),
              child: StreamBuilder<bool>(
                  stream: _walletKeyEntryController.readyToSave.stream,
                  builder: (BuildContext context, AsyncSnapshot<bool> value) {
                    return RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16))),
                      child: AppText.body(
                          text: "ADD",
                          color: AppColors.text_light,
                          letterSpacing: 1.25,
                          lineHeight: 1.14),
                      color: AppColors.purple,
                      onPressed: _walletKeyEntryController.readyToSave.value
                          ? _walletKeyEntryController.save
                          : null,
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _walletKeyEntryController.dispose();
  }
}
