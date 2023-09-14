import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/services.dart';
import 'package:orchid/vpn/orchid_vpn_config/orchid_vpn_config_import.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/common/qrcode_scan.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/pages/settings/advanced_configuration_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rxdart/rxdart.dart';

enum ImportExportMode { Import, Export }

// Returns true if the configuration string is valid
typedef ImportResult = void Function(String config);

/// A page presenting a full screen editable text box for importing or
/// exporting configuration.
class ImportExportConfig extends StatefulWidget {
  final ImportExportMode mode;
  final String title;
  final OrchidConfigValidator? validator;
  final ImportResult? onImport;
  final String? config;

  ImportExportConfig(
      {Key? key,
      required this.mode,
      required this.title,
      this.validator,
      this.config,
      this.onImport})
      : super(key: key);

  ImportExportConfig.import(
      {required String title,
      required OrchidConfigValidator validator,
      required ImportResult onImport})
      : this(
            title: title,
            mode: ImportExportMode.Import,
            validator: validator,
            onImport: onImport);

  ImportExportConfig.export({
    required String title,
    required String config,
  }) : this(
          title: title,
          mode: ImportExportMode.Export,
          config: config,
        );

  @override
  _ImportExportConfigState createState() => _ImportExportConfigState();
}

class _ImportExportConfigState extends State<ImportExportConfig> {
  String? _configFileTextLastSaved;
  final _configFileTextController = TextEditingController();
  bool _showQRScanner = false;

  // The import or copy action is enabled, subject to mode
  BehaviorSubject<bool> _actionEnabled = BehaviorSubject<bool>.seeded(false);

  @override
  void initState() {
    super.initState();

    setState(() {
      _configFileTextController.text = widget.config ?? '';
    });

    // Import mode init
    if (widget.mode == ImportExportMode.Import) {
      _configFileTextController.addListener(() {
        var text = _configFileTextController.text;
        var dirty = text != _configFileTextLastSaved;
        var valid = widget.validator != null ? widget.validator!(text) : true;
        _actionEnabled.add(valid && dirty);
      });
      setState(() {
        _configFileTextLastSaved = widget.config;
      });
    }
    // Export mode init
    else {
      // Copy always enabled
      _actionEnabled.add(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
        child: TitledPage(title: widget.title, child: buildPage(context)));
  }

  Widget buildPage(BuildContext context) {
    bool showQRImportExportButton = widget.mode == ImportExportMode.Export ||
        (widget.mode == ImportExportMode.Import &&
            OrchidPlatform.supportsScanning);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _showQRScanner
            ? QRCodeScanner(
                onCode: (String text) {
                  setState(() {
                    _configFileTextController.text = text;
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 16, bottom: 24),
                      child: OrchidConfigTextBox(
                        textController: _configFileTextController,
                        readOnly: widget.mode == ImportExportMode.Export,
                      ),
                    ),
                  ),

                  // Import / Export button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (showQRImportExportButton) ...[
                        _buildQRImportExportButton(),
                        padx(8),
                      ],
                      Container(
                        child: StreamBuilder<Object>(
                            stream: _actionEnabled.stream,
                            builder: (context, snapshot) {
                              return RoundedRectButton(
                                  text: widget.mode == ImportExportMode.Import
                                      ? context.s.import.toUpperCase()
                                      : context.s.copy.toUpperCase(),
                                  textColor: Colors.black,
                                  onPressed:
                                      _actionEnabled.value ? _doAction : null);
                            }),
                      ),
                    ],
                  ),

                  SizedBox(height: 24)
                ],
              ),
      ),
    );
  }

  Widget _buildQRImportExportButton() {
    return FlatButtonDeprecated(
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(width: 1, color: Colors.black54)),
        child: widget.mode == ImportExportMode.Export
            ? OrchidAsset.svg.qr_scan
            : OrchidAsset.svg.scan,
      ),
      onPressed: _doQRCodeAction,
    );
  }

  void _doAction() {
    if (widget.mode == ImportExportMode.Import) {
      _importText();
    } else {
      _copyToClipboard();
    }
  }

  void _importText() {
    _actionEnabled.add(false);
    var newConfig = _configFileTextController.text;
    if (widget.onImport != null) {
      widget.onImport!(newConfig);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.config ?? ''));
  }

  void _doQRCodeAction() {
    if (widget.mode == ImportExportMode.Import) {
      _importQR();
    } else {
      _exportQR();
    }
  }

  void dispose() {
    super.dispose();
    _actionEnabled.close();
  }

  void _importQR() async {
    setState(() {
      _showQRScanner = true;
    });
  }

  void _exportQR() {
    if (widget.config == null) {
      return;
    }
    AppDialogs.showAppDialog(
        context: context,
        title: context.s.myOrchidConfig + ':',
        body: Container(
          width: 250,
          height: 250,
          child: Center(
            child: QrImage(
              data: _configFileTextController.text = widget.config ?? '',
              backgroundColor: Colors.white,
              version: QrVersions.auto,
              size: 250.0,
            ),
          ),
        ));
  }
}
