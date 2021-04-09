
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/qrcode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

typedef ImportAccountCompletion = void Function(
    ParseOrchidAccountResult result);

// Used from the LegacyWelcomeDialog and AddHopPage->ScanOrPasteDialog
class ScanOrPasteOrchidAccount extends StatefulWidget {
  final ImportAccountCompletion onImportAccount;
  final double spacing;
  final bool v0Only;

  const ScanOrPasteOrchidAccount(
      {Key key,
      @required this.onImportAccount,
      this.spacing,
      this.v0Only = false})
      : super(key: key);

  @override
  _ScanOrPasteOrchidAccountState createState() =>
      _ScanOrPasteOrchidAccountState();
}

class _ScanOrPasteOrchidAccountState extends State<ScanOrPasteOrchidAccount> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var showIcons = screenWidth >= AppSize.iphone_xs.width;
    bool pasteOnly = OrchidPlatform.isMacOS;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildPasteButton(showIcons),
          if (!pasteOnly) ...[
            padx(widget.spacing ?? 24),
            _buildScanButton(showIcons),
          ],
        ],
      ),
    );
  }

  TitleIconButton _buildPasteButton(bool showIcons) {
    return TitleIconButton(
        text: s.paste,
        trailing: showIcons
            ? Icon(Icons.content_paste, color: AppColors.teal_3)
            : SizedBox(),
        textColor: AppColors.teal_3,
        backgroundColor: Colors.white,
        onPressed: _pasteCode);
  }

  TitleIconButton _buildScanButton(bool showIcons) {
    return TitleIconButton(
        text: s.scan,
        trailing: showIcons
            ? Image.asset("assets/images/scan.png", color: Colors.white)
            : SizedBox(),
        textColor: Colors.white,
        backgroundColor: AppColors.teal_3,
        onPressed: _scanCode);
  }

  void _scanCode() async {
    ParseOrchidAccountResult parseAccountResult;
    try {
      String text = await QRCode.scan();
      if (text == null) {
        log("user cancelled scan");
        return;
      }
      parseAccountResult = await _parse(text);
    } catch (err) {
      print("error parsing scanned orchid account: $err");
    }
    if (parseAccountResult != null) {
      widget.onImportAccount(parseAccountResult);
    } else {
      _scanQRCodeError();
    }
  }

  void _pasteCode() async {
    ParseOrchidAccountResult parseAccountResult;
    try {
      ClipboardData data = await Clipboard.getData('text/plain');
      String text = data.text;
      try {
        parseAccountResult = await _parse(text);
      } catch (err) {
        print("error parsing pasted orchid account: $err");
      }
    } catch (err) {
      print("error parsing pasted orchid account: $err");
    }
    if (parseAccountResult != null) {
      widget.onImportAccount(parseAccountResult);
    } else {
      _pasteCodeError();
    }
  }

  void _scanQRCodeError() {
    AppDialogs.showAppDialog(
        context: context,
        title: s.invalidQRCode,
        bodyText: s.theQRCodeYouScannedDoesNot);
  }

  void _pasteCodeError() {
    AppDialogs.showAppDialog(
        context: context,
        title: s.invalidCode,
        bodyText: s.theCodeYouPastedDoesNot);
  }

  Future<ParseOrchidAccountResult> _parse(String text) async {
    return await ParseOrchidAccountResult.parse(text, v0Only: widget.v0Only);
  }

  S get s {
    return S.of(context);
  }
}
