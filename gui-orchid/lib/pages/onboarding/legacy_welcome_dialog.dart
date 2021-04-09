import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/circuit/add_hop_page.dart';
import 'package:orchid/pages/circuit/scan_paste_account.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/link_text.dart';

class LegacyWelcomeDialog {
  static Future<void> show(
      {@required BuildContext context, AddFlowCompletion onAddFlowComplete}) {
    S s = S.of(context);
    var bodyStyle = TextStyle(fontSize: 16, color: Color(0xff504960));

    var topText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text: "\n" + s.orchidRequiresAccountInstruction, style: bodyStyle),
      ],
    );

    var bodyText = TextSpan(
      children: <TextSpan>[
        TextSpan(text: s.createOrchidAccount, style: AppText.dialogTitle),
        TextSpan(
            text: "\n\n" + s.youNeedEthereumWallet + "\n\n" + s.loadMsg + " ",
            style: bodyStyle),
        LinkTextSpan(
          text: "account.orchid.com",
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: OrchidUrls.accountOrchid,
        ),
        TextSpan(
            text: " " + s.inYourWalletBrowserInstruction, style: bodyStyle),
      ],
    );

    var bottomText = TextSpan(
      children: <TextSpan>[
        TextSpan(text: s.needMoreHelp + "?", style: AppText.dialogTitle),
        LinkTextSpan(
          text: "\n\n" + s.readTheGuide + ".",
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: 'https://orchid.com/join',
        ),
      ],
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        double screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    RichText(
                        text: TextSpan(
                            text: screenWidth > AppSize.iphone_se.width
                                ? s.addOrchidAccount
                                : s.addAccount,
                            style: AppText.dialogTitle)),
                    Container(
                      width: 40,
                      child: FlatButton(
                        child: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ],
                ),
                RichText(text: topText),
                pady(12),
                ScanOrPasteOrchidAccount(
                  spacing: screenWidth < AppSize.iphone_12_max.width ? 8 : 16,
                  onImportAccount: (ParseOrchidAccountResult result) async {
                    var hop = await OrchidVPNConfigV0.importAccountAsHop(
                        result.account);
                    Navigator.of(context)
                        .pop(); // TODO: probably not necessary?
                    onAddFlowComplete(hop);
                  },
                  v0Only: true,
                ),
                Divider(thickness: 1.0),
                pady(16),
                RichText(text: bodyText),
                pady(24),
                RichText(text: bottomText),
                pady(24)
              ],
            ),
          ),
        );
      },
    );
  }
}
