import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/orchid/field/orchid_labeled_identity_field.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/localization.dart';

typedef ImportAccountCompletion = void Function(
    ParseOrchidIdentityOrAccountResult result);

// Used from the AccountManagerPage and AdHopPage:
// Dialog that contains the two button scan/paste control.
class ScanOrPasteIdentityDialog extends StatefulWidget {
  final ImportAccountCompletion onImportAccount;

  const ScanOrPasteIdentityDialog({
    Key? key,
    required this.onImportAccount,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required ImportAccountCompletion onImport,
  }) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ScanOrPasteIdentityDialog(
            onImportAccount: onImport,
          );
        });
  }

  @override
  State<ScanOrPasteIdentityDialog> createState() =>
      _ScanOrPasteIdentityDialogState();
}

class _ScanOrPasteIdentityDialogState extends State<ScanOrPasteIdentityDialog> {
  ParseOrchidIdentityOrAccountResult? _parsed;

  @override
  Widget build(BuildContext context) {
    final pasteOnly = OrchidPlatform.doesNotSupportScanning;
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
                              text: s.importOrchidIdentity,
                              style: OrchidText.title)),
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
                    child: Column(
                      children: [
                        OrchidLabeledImportIdentityField(
                          label: s.orchidIdentity,
                          onChange: (parsed) {
                            setState(() {
                              _parsed = parsed;
                            });
                          },
                        ),
                        OrchidImportButton(
                          enabled: _parsed != null,
                          onPressed: _doImportAccount,
                        ).top(24),
                      ],
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

  void _doImportAccount() {
    if (_parsed == null) {
      return;
    }
    widget.onImportAccount(_parsed!);
    Navigator.of(context).pop();
  }
}

class OrchidCloseButton extends StatelessWidget {
  const OrchidCloseButton({
    Key? key,
    required this.context,
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

class OrchidImportButton extends StatelessWidget {
  const OrchidImportButton({
    Key? key,
    required this.enabled,
    required this.onPressed,
  }) : super(key: key);

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 52,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor:
              enabled ? OrchidColors.enabled : OrchidColors.disabled,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          // side: BorderSide(width: 2, color: Colors.white),
        ),
        child: Text(
          context.s.import.toUpperCase(),
        ).button.black,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
