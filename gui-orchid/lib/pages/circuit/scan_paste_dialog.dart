import 'dart:io';

import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/circuit/add_hop_page.dart';
import 'package:orchid/pages/circuit/scan_paste_account.dart';
import 'package:orchid/pages/common/formatting.dart';

// Used from the AdHopPage:
// Dialog that contains the two button scan/paste control.
class ScanOrPasteDialog extends StatelessWidget {
  final AddFlowCompletion onAddFlowComplete;

  const ScanOrPasteDialog({
    Key key,
    this.onAddFlowComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    S s = S.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    bool pasteOnly = Platform.isMacOS;

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
                    spacing:
                        screenWidth < AppSize.iphone_xs_max.width ? 8 : 16,
                    onImportAccount: (ParseOrchidAccountResult result) async {
                      var hop = await OrchidVPNConfig.importAccountAsHop(result);
                      Navigator.of(context).pop();
                      onAddFlowComplete(hop);
                    }),
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
