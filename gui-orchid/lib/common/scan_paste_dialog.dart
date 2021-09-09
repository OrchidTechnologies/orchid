import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_account_config/orchid_account_v1.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/common/scan_paste_account.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

// Used from the AccountManagerPage and AdHopPage:
// Dialog that contains the two button scan/paste control.
class ScanOrPasteDialog extends StatelessWidget {
  final ImportAccountCompletion onImportAccount;
  final bool v0Only;

  const ScanOrPasteDialog({
    Key key,
    this.onImportAccount,
    this.v0Only = false,
  }) : super(key: key);

  static Future<void> show({
    BuildContext context,
    ImportAccountCompletion onImportAccount,
    bool v0Only = false,
  }) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ScanOrPasteDialog(
            onImportAccount: onImportAccount,
            v0Only: v0Only,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    S s = S.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    bool pasteOnly = OrchidPlatform.isMacOS ||
        OrchidPlatform.isWeb ||
        OrchidPlatform.isWindows ||
        OrchidPlatform.isLinux;

    var titleTextV0 = pasteOnly ? s.pasteAccount : s.scanOrPasteAccount;
    var bodyTextV0 = pasteOnly
        ? s.pasteYourExistingAccountBelowToAddItAsA
        : s.scanOrPasteYourExistingAccountBelowToAddIt;
    var titleTextV1 = s.importAnOrchidAccount;
    var bodyTextV1 = pasteOnly
        ? s.pasteAnOrchidKeyFromTheClipboardToImportAll
        : s.scanOrPasteAnOrchidKeyFromTheClipboardTo;

    return AlertDialog(
      backgroundColor: OrchidColors.dark_background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      content: StreamBuilder<bool>(
          stream: UserPreferences().guiV0.stream(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return Container();
            }
            var guiV0 = snapshot.data;
            var titleText = guiV0 ? titleTextV0 : titleTextV1;
            var bodyText = guiV0 ? bodyTextV0 : bodyTextV1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    FittedBox(
                      child: Row(
                        children: <Widget>[
                          RichText(
                              text: TextSpan(
                                  text: titleText, style: OrchidText.title)),
                          _buildCloseButton(context)
                        ],
                      ),
                    ),
                    pady(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: RichText(
                          text: TextSpan(children: [
                        TextSpan(text: bodyText + ' ', style: OrchidText.body2),
                        OrchidText.buildLearnMoreLinkTextSpan(
                            context: context,
                            color: OrchidColors.purple_bright),
                      ])),
                    ),
                    pady(16),
                    FittedBox(
                      child: ScanOrPasteOrchidAccount(
                        spacing:
                            screenWidth < AppSize.iphone_12_max.width ? 8 : 16,
                        onImportAccount:
                            (ParseOrchidAccountResult result) async {
                          onImportAccount(result);
                          Navigator.of(context).pop();
                        },
                        v0Only: v0Only,
                        pasteOnly: pasteOnly,
                      ),
                    ),
                    pady(16),
                  ],
                ),
              ],
            );
          }),
    );
  }

  Container _buildCloseButton(BuildContext context) {
    return Container(
      width: 40,
      child: FlatButton(
        child: Icon(Icons.close, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
