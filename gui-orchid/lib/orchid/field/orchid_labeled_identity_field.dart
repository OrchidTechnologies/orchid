import 'package:orchid/orchid/orchid.dart';
import 'package:browser_detector/browser_detector.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/common/qrcode_scan.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:flutter/services.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';

/// Scan or paste an identity
class OrchidLabeledImportIdentityField extends StatefulWidget {
  final String label;

  /// Callback fires on changes with either a valid parsed account or null if the form state is invalid or incomplete.
  final void Function(ParseOrchidIdentityOrAccountResult? parsed) onChange;

  // final double spacing;

  const OrchidLabeledImportIdentityField({
    Key? key,
    required this.label,
    required this.onChange,
    // this.spacing,
  }) : super(key: key);

  @override
  _OrchidLabeledImportIdentityFieldState createState() =>
      _OrchidLabeledImportIdentityFieldState();
}

class _OrchidLabeledImportIdentityFieldState
    extends State<OrchidLabeledImportIdentityField> {
  var _pasteField = TextEditingController();

  // cache the results of the last validation
  var isValid = false;

  bool get _hasText => (_pasteField.text ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pasteField.addListener(_onTextFieldChange);
  }

  @override
  Widget build(BuildContext context) {
    final showPaste = !BrowserDetector().browser.isFirefox;
    return OrchidLabeledTextField(
      label: widget.label,
      hintText: 'account={ secret:...',
      controller: _pasteField,
      trailing: showPaste ? _buildTrailing() : null,
      error: _hasText && !isValid,
    ).pady(8);
  }

  Widget _buildTrailing() {
    final pasteOnly = OrchidPlatform.doesNotSupportScanning;
    return Row(
      children: [
        if (pasteOnly)
          SizedBox(
            width: 40,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(left: 16.0),
              ),
              child: Icon(Icons.paste, color: OrchidColors.tappable),
              onPressed: _pasteCode,
            ),
          ),
        if (!pasteOnly)
          SizedBox(
            width: 40,
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
    ).right(12);
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
      if (data?.text != null) {
        setState(() {
          _pasteField.text = data!.text!;
        });
      }
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
      isValid = true;
      log("pasted code valid = $parsed");
    } catch (err, stack) {
      widget.onChange(null);
      isValid = false;
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
