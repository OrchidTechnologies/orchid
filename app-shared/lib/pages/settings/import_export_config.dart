import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:rxdart/rxdart.dart';

import '../app_colors.dart';
import '../app_text.dart';

enum ImportExportMode { Import, Export }

// Returns true if the configuration string is valid
typedef ConfigValidator = bool Function(String config);
typedef ImportResult = void Function(String config);

/// A page presenting a full screen editable text box for importing or
/// exporting configuration.
// TODO: Update the advanced ConfigurationPage to use this widget.
class ImportExportConfig extends StatefulWidget {
  final ImportExportMode mode;
  final String title;
  final ConfigValidator validator;
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
      {@required String title, ConfigValidator validator, ImportResult onImport})
      : this(title: title, mode: ImportExportMode.Import, validator: validator, onImport: onImport);

  ImportExportConfig.export({@required String title, @required String config})
      : this(title: title, mode: ImportExportMode.Export, config: config);

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 24),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SingleChildScrollView(
                      child: TextFormField(
                    readOnly: widget.mode == ImportExportMode.Export,
                    autocorrect: false,
                    autofocus: false,
                    keyboardType: TextInputType.multiline,
                    style: AppText.logStyle.copyWith(color: AppColors.grey_2),
                    controller: _configFileTextController,
                    maxLines: 99999,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelStyle: AppText.textLabelStyle,
                    ),
                  )),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(width: 2.0, color: AppColors.neutral_5),
                  ),
                ),
              ),
            ),

            // Import / Export button
            Center(
              child: Container(
                child: StreamBuilder<Object>(
                    stream: _actionEnabled.stream,
                    builder: (context, snapshot) {
                      return RoundedRectRaisedButton(
                          text: widget.mode == ImportExportMode.Import ? "IMPORT" : "COPY",
                          onPressed: _actionEnabled.value ? _doAction : null);
                    }),
              ),
            ),

            SizedBox(height: 24)
          ],
        ),
      ),
    );
  }

  void _doAction() {
    if (widget.mode == ImportExportMode.Import) {
      _import();
    } else {
      _copy();
    }
  }

  void _import() {
    _actionEnabled.add(false);
    var newConfig = _configFileTextController.text;
    widget.onImport(newConfig);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.config));
  }

  void dispose() {
    super.dispose();
    _actionEnabled.close();
  }
}
