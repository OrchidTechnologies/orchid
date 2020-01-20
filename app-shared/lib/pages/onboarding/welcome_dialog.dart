import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_vpn_config.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/circuit/scan_paste_account.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/link_text.dart';

class WelcomeDialog {
  static Future<void> show({
    @required BuildContext context,
  }) {
    var bodyStyle = TextStyle(fontSize: 16, color: Color(0xff504960));

    var topText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text:
                "\nOrchid requires an Orchid account.  Scan or paste your existing account below"
                " to get started.",
            style: bodyStyle),
      ],
    );

    var bodyText = TextSpan(
      children: <TextSpan>[
        TextSpan(text: "Create Orchid Account", style: AppText.dialogTitle),
        TextSpan(
            text:
                ("\n\nYou'll need an Ethereum Wallet in order to create an Orchid account."
                    "\n\nLoad "),
            style: bodyStyle),
        LinkTextSpan(
          text: "account.orchid.com",
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: 'https://account.orchid.com',
        ),
        TextSpan(
            text: " in your wallet's browser to get started.",
            style: bodyStyle),
      ],
    );

    var bottomText = TextSpan(
      children: <TextSpan>[
        TextSpan(text: "Need more help?", style: AppText.dialogTitle),
        LinkTextSpan(
          text: "\n\nRead the guide.",
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: 'https://orchid.com/join',
        ),
      ],
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
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
                            text: "Add Orchid Account",
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
                    spacing: 8,
                    onImportAccount: (result) {
                      _importAccount(context, result);
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

  // Save the new hop
  static void _importAccount(
      BuildContext context, ParseOrchidAccountResult result) async {
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
    // Save the new hop
    var circuit = await UserPreferences().getCircuit();
    circuit.hops.add(hop);
    await UserPreferences().setCircuit(circuit);
    // Notify that the hops config has changed externally
    OrchidAPI().circuitConfigurationChanged.add(null);
    // End the dialog
    Navigator.of(context).pop();
  }
}
