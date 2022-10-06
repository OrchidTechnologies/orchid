import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../orchid/menu/orchid_popup_menu_button.dart';

class DappSettingsButton extends StatefulWidget {
  final int contractVersionSelected;
  final void Function(int version) selectContractVersion;
  final Set<int> contractVersionsAvailable;
  final VoidCallback deployContract;

  DappSettingsButton({
    Key key,
    this.contractVersionSelected,
    this.selectContractVersion,
    this.contractVersionsAvailable,
    this.deployContract,
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
    return OrchidPopupMenuButton<String>(
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
          case 'contract':
            widget.deployContract();
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
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildIdenticonsPref,
          ),
          PopupMenuDivider(height: 1.0),
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildLanguagePref,
          ),
          if (showContractVersions) ...[
            PopupMenuDivider(height: 1.0),
            SubmenuPopopMenuItemBuilder<String>(
              builder: _buildContractVerionsPref,
            ),
          ],
          PopupMenuDivider(height: 1.0),
          PopupMenuItem<String>(
            value: 'logs',
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text(s.viewLogs, style: _textStyle),
            ),
          ),
          if (widget.deployContract != null)
            PopupMenuItem<String>(
              value: 'contract',
              height: _height,
              child: SizedBox(
                width: _width,
                child: Text(s.deployContract, style: _textStyle),
              ),
            ),
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildAbout,
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
    log('XXX: open logs page');
    return Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return LoggingPage();
    }));
  }

  Widget _buildLanguagePref(bool expanded) {
    return UserPreferences().languageOverride.builder((languageOverride) {
      return ExpandingPopupMenuItem(
        expanded: expanded,
        title: s.language,
        currentSelectionText: OrchidLanguage.languages[languageOverride] ?? '',
        expandedContent: _languageOptions(languageOverride),
        expandedHeight: 690,
        textStyle: _textStyle,
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
          title: s.systemDefault,
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
        return ExpandingPopupMenuItem(
          expanded: expanded,
          title: s.identiconStyle,
          currentSelectionText:
              (!expanded ? (useBlockies ? s.blockies : s.jazzicon) : ''),
          expandedContent: _identiconOptions(useBlockies),
          expandedHeight: 108,
          textStyle: _textStyle,
        );
      },
    );
  }

  Widget _buildAbout(bool expanded) {
    final buildCommit =
        const String.fromEnvironment('build_commit', defaultValue: '...');
    final githubUrl =
        'https://github.com/OrchidTechnologies/orchid/tree/$buildCommit/web-ethereum/dapp2';
    return ExpandingPopupMenuItem(
      expanded: expanded,
      title: s.about,
      expandedContent: _listMenuItem(
        selected: false,
        title: s.dappVersion + ': ' + buildCommit,
        onTap: () async {
          launchUrlString(githubUrl);
        },
      ),
      expandedHeight: 58,
      textStyle: _textStyle,
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
          title: s.blockies,
          onTap: () async {
            await pref.set(true);
          },
        ),
        PopupMenuDivider(height: 1.0),
        _listMenuItem(
          selected: !useBlockies,
          title: s.jazzicon,
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
    return ExpandingPopupMenuItem(
      expanded: expanded,
      title: s.contractVersion,
      currentSelectionText: (!expanded ? selected.toString() : ''),
      expandedContent: _contractVersionOptions(),
      expandedHeight: available.length * 54.0,
      textStyle: _textStyle,
    );
  }

  Widget _contractVersionOptions() {
    return contractVersionOptions(
      context: context,
      available: widget.contractVersionsAvailable,
      selected: widget.contractVersionSelected,
      select: widget.selectContractVersion,
      textStyle: _textStyle,
    );
  }

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
        DappSettingsButtonUtils.listMenuItem(
          context: context,
          textStyle: textStyle,
          selected: selected == 0,
          title: context.s.version0,
          onTap: () {
            select(0);
          },
        ),
      );
    }
    if (available.contains(1)) {
      list.add(
        DappSettingsButtonUtils.listMenuItem(
          context: context,
          textStyle: textStyle,
          selected: selected == 1,
          title: context.s.version1,
          onTap: () {
            select(1);
          },
        ),
      );
    }
    return list;
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

class ExpandingPopupMenuItem extends StatelessWidget {
  final bool expanded;
  final String title;
  final String currentSelectionText;
  final double expandedHeight;
  final Widget expandedContent;
  final TextStyle textStyle;
  final double collapsedHeight;

  const ExpandingPopupMenuItem({
    Key key,
    @required this.expanded,
    @required this.title,
    this.currentSelectionText,
    @required this.expandedHeight,
    @required this.expandedContent,
    @required this.textStyle,
    this.collapsedHeight = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: collapsedHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: textStyle),
              Row(
                children: [
                  if (currentSelectionText != null)
                    Text(currentSelectionText, style: textStyle).right(8),
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
}

class DappSettingsButtonUtils {
  static PopupMenuItem listMenuItem({
    @required BuildContext context,
    @required bool selected,
    String title,
    Widget body,
    @required VoidCallback onTap,
    @required TextStyle textStyle,
  }) {
    return PopupMenuItem(
      padding: EdgeInsets.zero,
      child: ListTile(
        selected: selected,
        selectedTileColor: OrchidColors.selected_color_dark,
        title: body ?? Text(title, style: textStyle),
        onTap: () {
          // Close the menu item
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
}
