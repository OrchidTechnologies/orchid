import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/formatting.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:styled_text/styled_text.dart';

class ExportIdentityDialog extends StatefulWidget {
  const ExportIdentityDialog({
    Key key,
    @required this.body,
    @required this.config,
  }) : super(key: key);

  final StyledText body;
  final String config;

  @override
  _ExportIdentityDialogState createState() => _ExportIdentityDialogState();
}

class _ExportIdentityDialogState extends State<ExportIdentityDialog> {
  bool _showCopiedText = false;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);

    return Container(
      padding: EdgeInsets.all(8),
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.body,
          pady(16),
          TextButton(
            onPressed: _onPressed,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    QrImage(
                      data: widget.config,
                      version: QrVersions.auto,
                      size: 180.0,
                    ),
                    pady(8),
                    Container(
                      width: 180,
                      height: 20,
                      child: _showCopiedText
                          ? Center(child: Text(s.copied))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.copy,
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                                Icon(
                                  Icons.download_sharp,
                                  color: Colors.deepPurple,
                                )
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPressed() async {
    Clipboard.setData(ClipboardData(text: widget.config));
    setState(() {
      _showCopiedText = true;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _showCopiedText = false;
    });
  }
}
