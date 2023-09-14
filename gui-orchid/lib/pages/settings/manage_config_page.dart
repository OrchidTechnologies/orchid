import 'package:flutter/material.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/vpn/orchid_vpn_config/orchid_vpn_config_generate.dart';
import 'package:orchid/vpn/orchid_vpn_config/orchid_vpn_config_import.dart';
import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/pages/settings/import_export_config.dart';
import 'package:orchid/util/localization.dart';
import '../../common/app_text.dart';

/// The manage configuration page allows export and import of the hops config
class ManageConfigPage extends StatefulWidget {
  @override
  _ManageConfigPageState createState() => _ManageConfigPageState();
}

class _ManageConfigPageState extends State<ManageConfigPage> {
  @override
  void initState() {
    super.initState();
    ScreenOrientation.portrait();
    initStateAsync();
  }

  void initStateAsync() async {}

  Widget build(BuildContext context) {
    var instructionsStyle = AppText.listItem.copyWith(
        color: Colors.white, fontStyle: FontStyle.italic, fontSize: 14);
    return TitledPage(
      title: s.manageConfiguration,
      child: Column(
        children: <Widget>[
          pady(24),
          Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
            child: Text(s.warningThesefeature, style: instructionsStyle),
          ),
          Divider(),
          pady(16),
          PageTile(
            title: s.exportHopsConfiguration,
            trailing: RaisedButtonDeprecated(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24))),
              color: OrchidColors.purple_bright,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.save, color: Colors.black),
                    padx(8),
                    Text(
                      s.export,
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              onPressed: _doExport,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
            child:
                Text(s.warningExportedConfiguration, style: instructionsStyle),
          ),
          Divider(),
          pady(16),
          PageTile(
            title: s.importHopsConfiguration,
            trailing: RaisedButtonDeprecated(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24))),
              color: OrchidColors.purple_bright,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.input, color: Colors.black),
                    padx(8),
                    Text(
                      s.import,
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              onPressed: _doImport,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
            child:
                Text(s.warningImportedConfiguration, style: instructionsStyle),
          ),
          pady(16),
          Divider(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
  }

  void _doExport() async {
    var config = '// Circuit\n' +
        (await OrchidVPNConfigGenerate.generateConfig(forExport: true));
    var keys = UserPreferencesKeys()
        .keys
        .get()!
        .map((storedKey) => storedKey.formatSecretFixed())
        .toList();
    config += '\n\n// All keys\nkeys=' + keys.toString();
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return ImportExportConfig.export(
        title: s.exportHopsConfiguration,
        config: config,
      );
    }));
  }

  void _doImport() {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return ImportExportConfig.import(
        title: s.importHopsConfiguration,
        validator: OrchidVPNConfigValidationV0.configValid,
        onImport: _importConfig,
      );
    }));
  }

  void _importConfig(String config) async {
    await OrchidVPNConfigImport.importConfig(config);
    Navigator.pop(context);
  }
}
