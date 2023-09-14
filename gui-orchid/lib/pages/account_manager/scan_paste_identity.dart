import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/common/qrcode_scan.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:flutter/services.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/util/localization.dart';

// TODO: Replacing this with orchid/field/...
@deprecated
class ScanOrPasteOrchidIdentity extends StatefulWidget {
  /// Callback fires on changes with either a valid parsed account or null if the form state is invalid or incomplete.
  final void Function(ParseOrchidIdentityOrAccountResult? parsed) onChange;
  // final double spacing;
  final bool pasteOnly;

  const ScanOrPasteOrchidIdentity({
    Key? key,
    required this.onChange,
    required this.pasteOnly,
    // this.spacing,
  }) : super(key: key);

  @override
  _ScanOrPasteOrchidIdentityState createState() =>
      _ScanOrPasteOrchidIdentityState();
}

class _ScanOrPasteOrchidIdentityState extends State<ScanOrPasteOrchidIdentity> {
  var _pasteField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pasteField.addListener(_onTextFieldChange);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var showIcons = screenWidth >= AppSize.iphone_xs.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildPasteField(showIcons),
    );
  }

  Widget _buildPasteField(bool showIcons) {
    return OrchidTextField(
      hintText: '0x...',
      controller: _pasteField,
      trailing: Row(
        children: [
          if (widget.pasteOnly)
            SizedBox(
              width: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.only(left: 20.0),
                ),
                child: Icon(Icons.paste, color: OrchidColors.tappable),
                onPressed: _pasteCode,
              ),
            ),
          if (!widget.pasteOnly)
            SizedBox(
              width: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.only(left: 16.0),
                ),
                child: Image.asset(OrchidAssetImage.scan_path,
                    color: OrchidColors.tappable),
                onPressed: _scanCode,
              ),
            ),
        ],
      ),
    );
  }

  /// Scan a QR Code and add the text to the field
  void _scanCode() async {
    QRCodeScanner.scan(context, (String text) {
      try {
        if (text == null) {
          log("user cancelled scan");
          return;
        }
        setState(() {
          _pasteField.text = text;
        });
      } catch (err) {
        print("error scanning orchid account: $err");
      }
      _validateCodeAndFireCallback(fromScan: true);
    });
  }

  /// Paste code from the clipboard via the paste button
  // Note: Clipboard.getData() is not yet supported for web on Firefox.
  // https://github.com/flutter/flutter/issues/48581
  void _pasteCode() async {
    try {
      ClipboardData? data = await Clipboard.getData('text/plain');
      setState(() {
        _pasteField.text = data?.text ?? '';
      });
    } catch (err) {
      print("Can't get clipboard: $err");
    }
    _validateCodeAndFireCallback(fromPaste: true);
  }

  /// User entered text
  void _onTextFieldChange() {
    _validateCodeAndFireCallback();
  }

  void _validateCodeAndFireCallback(
      {bool fromPaste = false, bool fromScan = false}) {
    try {
      final parsed = _parse(_pasteField.text);
      widget.onChange(parsed);
      log("pasted code valid = $parsed");
    } catch (err, stack) {
      widget.onChange(null);
      if (fromPaste) {
        _pasteCodeError();
      } else if (fromScan) {
        _scanQRCodeError();
      }
      print("error parsing pasted orchid account: $err, \n$stack");
    }
    setState(() {});
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

  ParseOrchidIdentityOrAccountResult _parse(String text) {
    return OrchidAccountImport.parse(text);
  }

  @override
  void dispose() {
    _pasteField.removeListener(_onTextFieldChange);
    super.dispose();
  }
}
