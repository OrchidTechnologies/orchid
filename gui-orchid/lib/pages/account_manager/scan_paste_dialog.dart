import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/pages/account_manager/scan_paste_account.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/on_off.dart';

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
    final pasteOnly = OrchidPlatform.doesNotSupportScanning;
    var titleText = s.importAnOrchidAccount;
    var bodyText = pasteOnly
        ? s.pasteAnOrchidKeyFromTheClipboardToImportAll
        : s.scanOrPasteAnOrchidKeyFromTheClipboardTo;

    return AlertDialog(
      backgroundColor: OrchidColors.dark_background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      content: IntrinsicHeight(
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                pady(6),
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                          text: TextSpan(
                              text: titleText, style: OrchidText.title)),
                    ],
                  ).right(16),
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
                  child: SizedBox(
                    width: 300,
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
                ),
              ],
            ),
            Align(
                alignment: Alignment.topRight,
                child: OrchidCloseButton(context: context)),
          ],
        ),
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
      child: TextButton(
        child: Icon(Icons.close, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ).left(0);
  }
}
