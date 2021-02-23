
import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/circuit/scan_paste_account.dart';
import 'package:orchid/pages/common/formatting.dart';

// Used from the AdHopPage:
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
    bool pasteOnly = OrchidPlatform.isMacOS;

    return AlertDialog(
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
                        text: TextSpan(
                            text: pasteOnly
                                ? s.pasteAccount
                                : s.scanOrPasteAccount,
                            style: AppText.dialogTitle
                                .copyWith(fontWeight: FontWeight.bold))),
                    _buildCloseButton(context)
                  ],
                ),
              ),
              pady(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(pasteOnly
                    ? s.pasteYourExistingAccountBelowToAddItAsA
                    : s.scanOrPasteYourExistingAccountBelowToAddIt),
              ),
              pady(16),
              FittedBox(
                child: ScanOrPasteOrchidAccount(
                  spacing: screenWidth < AppSize.iphone_12_max.width ? 8 : 16,
                  onImportAccount: (ParseOrchidAccountResult result) async {
                    onImportAccount(result);
                    Navigator.of(context).pop();
                  },
                  v0Only: v0Only,
                ),
              ),
              pady(16),
            ],
          ),
        ],
      ),
    );
  }

  Container _buildCloseButton(BuildContext context) {
    return Container(
      width: 40,
      child: FlatButton(
        child: Icon(Icons.close),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
