import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_vpn_config.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/circuit/add_hop_page.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/circuit/scan_paste_account.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/link_text.dart';

class WelcomeDialog {
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
          url: 'https://account.orchid.com',
        ),
        TextSpan(
            text: " " + s.inYourWalletBrowserInstruction, style: bodyStyle),
      ],
    );

    var bottomText = TextSpan(
      children: <TextSpan>[
        TextSpan(text: s.needMoreHelp + "?", style: AppText.dialogTitle),
        LinkTextSpan(
          text: "\n\n"+s.readTheGuide+".",
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
                            text: screenWidth > AppSizes.iphone_se.width
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
                    spacing:
                        screenWidth < AppSizes.iphone_xs_max.width ? 8 : 16,
                    onImportAccount: (ParseOrchidAccountResult result) {
                      _importAccount(context,
                          result: result, onAddFlowComplete: onAddFlowComplete);
                    }),
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

  /// Create a hop from the parse result, save any new keys, and return the hop
  /// to the add flow completion.
  static void _importAccount(BuildContext context,
      {ParseOrchidAccountResult result,
      AddFlowCompletion onAddFlowComplete}) async {
    print(
        "result: ${result.account.funder}, ${result.account.signer}, new keys = ${result.newKeys.length}");
    // Save any new keys
    await UserPreferences().addKeys(result.newKeys);
    // Create the new hop
    CircuitHop hop = OrchidHop(
      curator: OrchidHop.appDefaultCurator,
      funder: result.account.funder,
      keyRef: result.account.signer.ref(),
    );
    // End the dialog
    Navigator.of(context).pop();
    onAddFlowComplete(hop);
  }
}
