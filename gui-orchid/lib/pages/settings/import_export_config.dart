import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/common/qrcode_scan.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/common/titled_page_base.dart';
import 'package:orchid/pages/settings/advanced_configuration_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ImportExportMode { Import, Export }

// Returns true if the configuration string is valid
typedef ImportResult = void Function(String config);

/// A page presenting a full screen editable text box for importing or
/// exporting configuration.
// TODO: Update the advanced ConfigurationPage to use this widget.
class ImportExportConfig extends StatefulWidget {
  final ImportExportMode mode;
  final String title;
  final OrchidConfigValidator validator;
  final ImportResult onImport;
  final String config;

  ImportExportConfig(
      {Key key,
      @required this.mode,
      @required this.title,
      this.validator,
      this.config,
      this.onImport})
      : super(key: key);

  ImportExportConfig.import(
      {@required String title,
      OrchidConfigValidator validator,
      ImportResult onImport})
      : this(
            title: title,
            mode: ImportExportMode.Import,
            validator: validator,
            onImport: onImport);

  ImportExportConfig.export({
    @required String title,
    @required String config,
  }) : this(
          title: title,
          mode: ImportExportMode.Export,
          config: config,
        );

  @override
  _ImportExportConfigState createState() => _ImportExportConfigState();
}

class _ImportExportConfigState extends State<ImportExportConfig> {
  String _configFileTextLastSaved;
  final _configFileTextController = TextEditingController();

  // The import or copy action is enabled, subject to mode
  BehaviorSubject<bool> _actionEnabled = BehaviorSubject<bool>.seeded(false);

  @override
  void initState() {
    super.initState();

    setState(() {
      _configFileTextController.text = widget.config;
    });

    // Import mode init
    if (widget.mode == ImportExportMode.Import) {
      _configFileTextController.addListener(() {
        var text = _configFileTextController.text;
        var dirty = text != _configFileTextLastSaved;
        var valid = widget.validator(text);
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
        (widget.mode == ImportExportMode.Import && !OrchidPlatform.isMacOS);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
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
                                ? s.import.toUpperCase()
                                : s.copy.toUpperCase(),
                            textColor: Colors.black,
                            onPressed: _actionEnabled.value ? _doAction : null);
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
    return FlatButton(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.black54)),
          child: widget.mode == ImportExportMode.Export
              ? SvgPicture.asset("assets/svg/qr_scan.svg")
              : SvgPicture.asset("assets/svg/scan.svg"),
        ),
        onPressed: _doQRCodeAction);
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
    widget.onImport(newConfig);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.config));
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
    String text = await QRCode.scan();
    if (text == null) {
      log("user cancelled scan");
      return;
    }
    if (widget.validator(text)) {
      setState(() {
        _configFileTextController.text = text;
      });
    }
  }

  void _exportQR() {
    AppDialogs.showAppDialog(
        context: context,
        title: "My Orchid Config" + ':',
        body: Container(
          width: 250,
          height: 250,
          child: Center(
            child: QrImage(
              data: _configFileTextController.text = widget.config,
              backgroundColor: Colors.white,
              version: QrVersions.auto,
              size: 250.0,
            ),
          ),
        ));
  }

  S get s {
    return S.of(context);
  }
}
