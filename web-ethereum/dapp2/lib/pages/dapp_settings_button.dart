import 'package:orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/popupmenu_submenu.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'dapp_header_popup_button.dart';

class DappSettingsButton extends StatefulWidget {
  final int contractVersionSelected;
  final void Function(int version) selectContractVersion;
  final Set<int> contractVersionsAvailable;

  DappSettingsButton({
    Key key,
    this.contractVersionSelected,
    this.selectContractVersion,
    this.contractVersionsAvailable,
  }) : super(key: key);

  @override
  State<DappSettingsButton> createState() => _DappSettingsButtonState();
}

class _DappSettingsButtonState extends State<DappSettingsButton> {
  final _width = 273.0;
  final _height = 50.0;
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    return DappHeaderPopupMenuButton<String>(
      width: 40,
      height: 40,
      selected: _buttonSelected,
      onSelected: (String item) {
        setState(() {
          _buttonSelected = false;
        });
        switch (item) {
          case 'logs':
            _openLogsPage(context);
            break;
        }
      },
      onCanceled: () {
        setState(() {
          _buttonSelected = false;
        });
      },
      itemBuilder: (itemBuilderContext) {
        final available = widget.contractVersionsAvailable;
        final selected = widget.contractVersionSelected;
        final showContractVersions =
            (available ?? {}).isNotEmpty && selected != null;

        setState(() {
          _buttonSelected = true;
        });

        return [
          SubmenuPopopMenuItem<String>(
            builder: _buildIdenticonsPref,
          ),
          PopupMenuDivider(height: 1.0),
          SubmenuPopopMenuItem<String>(
            builder: _buildLanguagePref,
          ),
          if (showContractVersions) ...[
            PopupMenuDivider(height: 1.0),
            SubmenuPopopMenuItem<String>(
              builder: _buildContractVerionsPref,
            ),
          ],
          PopupMenuDivider(height: 1.0),
          PopupMenuItem<String>(
            value: 'logs',
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text("View Logs", style: _textStyle),
            ),
          ),
        ];
      },
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
              width: 20, height: 20, child: OrchidAsset.svg.settings_gear)),
    );
  }

  Future _openLogsPage(BuildContext context) {
    log("XXX: open logs page");
    return Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return LoggingPage();
    }));
  }

  // TODO: Move this into ExpandingPopopMenuItem
  Widget _buildExpandableMenuItem({
    bool expanded,
    String title,
    String currentSelectionText,
    double expandedHeight,
    Widget expandedContent,
  }) {
    return Column(
      children: [
        SizedBox(
          height: _height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: _textStyle),
              Row(
                children: [
                  Text(currentSelectionText, style: _textStyle),
                  padx(8),
                  Icon(expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: Colors.white),
                ],
              ),
            ],
          ),
        ),
        AnimatedContainer(
          height: expanded ? expandedHeight : 0,
          duration: Duration(milliseconds: 250),
          child: expanded
              ? SingleChildScrollView(child: expandedContent)
              : Container(),
        ),
      ],
    );
  }

  Widget _buildLanguagePref(bool expanded) {
    return UserPreferences().languageOverride.builder((languageOverride) {
      return _buildExpandableMenuItem(
        expanded: expanded,
        title: "Language",
        currentSelectionText: OrchidLanguage.languages[languageOverride] ?? '',
        expandedContent: _languageOptions(languageOverride),
        expandedHeight: 690,
      );
    });
  }

  Widget _languageOptions(String selected) {
    var items = OrchidLanguage.languages.keys
        .map(
          (key) => _listMenuItem(
            selected: key == selected,
            title: OrchidLanguage.languages[key],
            onTap: () async {
              await UserPreferences().languageOverride.set(key);
            },
          ),
        )
        .toList()
        .separatedWith(
          PopupMenuDivider(height: 1.0),
        );

    // Default system language option
    items.insert(
        0,
        _listMenuItem(
          selected: selected == null,
          title: "System Default",
          onTap: () async {
            await UserPreferences().languageOverride.set(null);
          },
        ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  Widget _buildIdenticonsPref(bool expanded) {
    return UserPreferences().useBlockiesIdenticons.builder(
      (useBlockies) {
        if (useBlockies == null) {
          return Container();
        }
        return _buildExpandableMenuItem(
          expanded: expanded,
          title: "Identicon Style",
          currentSelectionText:
              (!expanded ? (useBlockies ? "Blockies" : "Jazzicon") : ''),
          expandedContent: _identiconOptions(useBlockies),
          expandedHeight: 108,
        );
      },
    );
  }

  Widget _identiconOptions(bool useBlockies) {
    final pref = UserPreferences().useBlockiesIdenticons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PopupMenuDivider(height: 1.0),
        _listMenuItem(
          selected: useBlockies,
          title: "Blockies",
          onTap: () async {
            await pref.set(true);
          },
        ),
        PopupMenuDivider(height: 1.0),
        _listMenuItem(
          selected: !useBlockies,
          title: "Jazzicon",
          onTap: () async {
            await pref.set(false);
          },
        ),
      ],
    );
  }

  Widget _buildContractVerionsPref(bool expanded) {
    final available = widget.contractVersionsAvailable;
    final selected = widget.contractVersionSelected;
    return _buildExpandableMenuItem(
      expanded: expanded,
      title: "Contract Version",
      currentSelectionText: (!expanded ? selected.toString() : ''),
      expandedContent: _contractVersionOptions(),
      expandedHeight: available.length * 54.0,
    );
  }

  Widget _contractVersionOptions() {
    return DappSettingsButtonUtils.contractVersionOptions(
      context: context,
      available: widget.contractVersionsAvailable,
      selected: widget.contractVersionSelected,
      select: widget.selectContractVersion,
      textStyle: _textStyle,
    );
  }

  Widget _listMenuItem({
    @required bool selected,
    @required String title,
    @required VoidCallback onTap,
  }) {
    return DappSettingsButtonUtils.listMenuItem(
      context: context,
      selected: selected,
      title: title,
      onTap: onTap,
      textStyle: _textStyle,
    );
  }
}

class DappSettingsButtonUtils {
  static Widget contractVersionOptions({
    BuildContext context,
    Set<int> available,
    int selected,
    void Function(int version) select,
    TextStyle textStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: contractVersionOptionsMenuItems(
        context: context,
        available: available,
        selected: selected,
        select: select,
        textStyle: textStyle,
      ).cast<Widget>().separatedWith(
        PopupMenuDivider(height: 1),
      ),
    );
  }

  static List<PopupMenuEntry> contractVersionOptionsMenuItems({
    @required BuildContext context,
    @required Set<int> available,
    @required int selected,
    @required void Function(int version) select,
    @required TextStyle textStyle,
  }) {
    List<PopupMenuItem> list = [];
    if (available.contains(0)) {
      list.add(
        listMenuItem(
          context: context,
          textStyle: textStyle,
          selected: selected == 0,
          title: "Version 0",
          onTap: () {
            select(0);
          },
        ),
      );
    }
    if (available.contains(1)) {
      list.add(
        listMenuItem(
          context: context,
          textStyle: textStyle,
          selected: selected == 1,
          title: "Version 1",
          onTap: () {
            select(1);
          },
        ),
      );
    }
    return list;
  }

  static PopupMenuItem listMenuItem({
    @required BuildContext context,
    @required bool selected,
    @required String title,
    @required VoidCallback onTap,
    @required TextStyle textStyle,
  }) {
    return PopupMenuItem(
      padding: EdgeInsets.zero,
      child: ListTile(
        selected: selected,
        selectedTileColor: OrchidColors.selected_color_dark,
        title: Text(title, style: textStyle),
        onTap: () {
          // Close the menu item
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
}
