import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/scan_paste_account.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

// Used from the AccountManagerPage and AdHopPage:
// Dialog that contains the two button scan/paste control.
class ScanOrPasteDialog extends StatelessWidget {
  final ImportAccountCompletion onImportAccount;

  const ScanOrPasteDialog({
    Key key,
    this.onImportAccount,
  }) : super(key: key);

  static Future<void> show({
    BuildContext context,
    ImportAccountCompletion onImportAccount,
  }) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ScanOrPasteDialog(
            onImportAccount: onImportAccount,
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

    var titleText = s.importAnOrchidAccount;
    var bodyText = pasteOnly
        ? s.pasteAnOrchidKeyFromTheClipboardToImportAll
        : s.scanOrPasteAnOrchidKeyFromTheClipboardTo;

    return AlertDialog(
      backgroundColor: OrchidColors.dark_background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
            children: <Widget>[
              FittedBox(
                child: Row(
                  children: <Widget>[
                    RichText(
                        text:
                            TextSpan(text: titleText, style: OrchidText.title)),
                    OrchidCloseButton(context: context)
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
                      context: context, color: OrchidColors.purple_bright),
                ])),
              ),
              pady(16),
              FittedBox(
                child: ScanOrPasteOrchidAccount(
                  spacing:
                      screenWidth < AppSize.iphone_12_pro_max.width ? 8 : 16,
                  onImportAccount: (ParseOrchidIdentityResult result) async {
                    onImportAccount(result);
                    Navigator.of(context).pop();
                  },
                  pasteOnly: pasteOnly,
                ),
              ),
              pady(16),
            ],
          ),
        ],
      ),
    );
  }
}

class OrchidCloseButton extends StatelessWidget {
  const OrchidCloseButton({
    Key key,
    @required this.context,
  }) : super(key: key);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
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
