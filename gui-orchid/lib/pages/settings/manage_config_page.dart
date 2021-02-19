import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/settings/import_export_config.dart';

import '../app_text.dart';

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
        color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 14);
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
            trailing: RaisedButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.save),
                  padx(8),
                  Text(s.export),
                ],
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
            trailing: RaisedButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.input),
                  padx(8),
                  Text(s.import),
                ],
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
    String hopsConfig = await OrchidVPNConfigV0.generateConfig();
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return ImportExportConfig.export(
        title: s.exportHopsConfiguration,
        config: hopsConfig,
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
    await OrchidVPNConfigV0.importConfig(config);
    Navigator.pop(context);
  }

  S get s {
    return S.of(context);
  }
}
