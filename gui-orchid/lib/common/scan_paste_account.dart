import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/qrcode_scan.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:flutter/services.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'app_colors.dart';

typedef ImportAccountCompletion = void Function(
    ParseOrchidIdentityResult result);

class ScanOrPasteOrchidAccount extends StatefulWidget {
  final ImportAccountCompletion onImportAccount;
  final double spacing;
  final bool pasteOnly;

  const ScanOrPasteOrchidAccount(
      {Key key,
      @required this.onImportAccount,
      this.spacing,
      @required this.pasteOnly})
      : super(key: key);

  @override
  _ScanOrPasteOrchidAccountState createState() =>
      _ScanOrPasteOrchidAccountState();
}

class _ScanOrPasteOrchidAccountState extends State<ScanOrPasteOrchidAccount> {
  var _pasteField = TextEditingController();
  bool _pastedCodeValid = false;

  @override
  void initState() {
    super.initState();
    _pasteField.addListener(_validatePastedCode);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var showIcons = screenWidth >= AppSize.iphone_xs.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!widget.pasteOnly) ...[
            _buildScanButton(showIcons),
            pady(32),
          ],
          _buildPasteField(showIcons),
        ],
      ),
    );
  }

  Widget _buildPasteField(bool showIcons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: OrchidTextField(
              hintText: '0x...',
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              controller: _pasteField,
              trailing: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(s.paste, style: OrchidText.button.purpleBright),
                    onPressed: _pasteCode),
              )),
        ),
        padx(16),
        SizedBox(
          width: 50,
          height: 52,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: _pastedCodeValid
                  ? OrchidColors.enabled
                  : OrchidColors.disabled,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              // side: BorderSide(width: 2, color: Colors.white),
            ),
            child: Text(
              s.ok,
              style: TextStyle().black,
            ),
            onPressed: _pastedCodeValid ? _parsePastedCode : null,
          ),
        ),
      ],
    );
  }

  TitleIconButton _buildScanButton(bool showIcons) {
    return TitleIconButton(
        text: s.scan,
        spacing: 6,
        trailing: showIcons
            ? Image.asset("assets/images/scan.png", color: Colors.white)
            : SizedBox(),
        textColor: Colors.white,
        backgroundColor: AppColors.teal_3,
        onPressed: _scanCode);
  }

  void _scanCode() async {
    ParseOrchidIdentityResult parseAccountResult;
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

  // Note: Clipboard.getData() is not yet supported for web on Firefox.
  // https://github.com/flutter/flutter/issues/48581
  void _pasteCode() async {
    try {
      ClipboardData data = await Clipboard.getData('text/plain');
      setState(() {
        _pasteField.text = data.text;
      });
    } catch (err) {
      print("Can't get clipboard: $err");
    }
  }

  void _validatePastedCode() async {
    try {
      await _parse(_pasteField.text);
      _pastedCodeValid = true;
    } catch (err) {
      _pastedCodeValid = false;
    }
    log("pasted code valid = $_pastedCodeValid");
    setState(() {});
  }

  void _parsePastedCode() async {
    ParseOrchidIdentityResult parseAccountResult;
    try {
      String text = _pasteField.text;
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

  Future<ParseOrchidIdentityResult> _parse(String text) async {
    return await ParseOrchidIdentityResult.parse(text);
  }

  S get s {
    return S.of(context);
  }
}
