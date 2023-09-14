import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_item_utils.dart';
import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';
import 'package:orchid/pages/help/open_source_page.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../orchid/menu/orchid_popup_menu_button.dart';

class DappSettingsButton extends StatefulWidget {
  final int? contractVersionSelected;
  final void Function(int version)? selectContractVersion;
  final Set<int>? contractVersionsAvailable;
  final VoidCallback? deployContract;

  DappSettingsButton({
    Key? key,
    this.contractVersionSelected,
    required this.selectContractVersion,
    required this.contractVersionsAvailable,
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
    final buildCommit =
        const String.fromEnvironment('build_commit', defaultValue: '...');
    final githubUrl =
        'https://github.com/OrchidTechnologies/orchid/tree/$buildCommit/web-ethereum/dapp2';
    return OrchidPopupMenuButton<dynamic>(
      width: 40,
      height: 40,
      selected: _buttonSelected,
      onSelected: (item) {
        setState(() {
          _buttonSelected = false;
        });
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

          // View contract links
          if (widget.contractVersionSelected != null)
            ..._viewContractLinkMenuItems(
                context: context,
                available: widget.contractVersionsAvailable!,
                selected: widget.contractVersionSelected!,
                textStyle: _textStyle),

          PopupMenuDivider(height: 1.0),

          PopupMenuItem<String>(
            onTap: () {
              Future.delayed(millis(0), () async {
                _openLogsPage(context);
              });
            },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text(s.viewLogs, style: _textStyle),
            ),
          ),

          PopupMenuDivider(height: 1.0),
          PopupMenuItem<String>(
            onTap: () {
              Future.delayed(millis(0), () async {
                _openLicensePage(context);
              });
            },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text(s.openSourceLicenses, style: _textStyle),
            ),
          ),

          PopupMenuDivider(height: 1.0),
          if (widget.deployContract != null)
            PopupMenuItem<String>(
              onTap: () {
                if (widget.deployContract != null) {
                  widget.deployContract!();
                }
              },
              height: _height,
              child: SizedBox(
                width: _width,
                child: Text(s.deployContract, style: _textStyle),
              ),
            ),

          // dapp version item
          _listMenuItem(
            selected: false,
            title: s.dappVersion + ': ' + buildCommit,
            onTap: () async {
              launchUrlString(githubUrl);
            },
          ),
          /*
          // about submenu
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildAbout,
          ),
           */
        ];
      },
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
              width: 20, height: 20, child: OrchidAsset.svg.settings_gear)),
    );
  }

  Future _openLogsPage(BuildContext context) {
    return Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return LoggingPage();
    }));
  }

  Future _openLicensePage(BuildContext context) {
    return Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return OpenSourcePage();
    }));
  }

  Widget _buildLanguagePref(bool expanded) {
    return UserPreferencesUI().languageOverride.builder((languageOverride) {
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

  Widget _languageOptions(String? selected) {
    var items = OrchidLanguage.languages.keys
        .map(
          (key) => _listMenuItem(
            selected: key == selected,
            title: OrchidLanguage.languages[key]!,
            onTap: () async {
              await UserPreferencesUI().languageOverride.set(key);
            },
          ),
        )
        .toList()
        .cast<PopupMenuEntry>() // so that we can add the items below
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
            await UserPreferencesUI().languageOverride.set(null);
          },
        ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  Widget _buildIdenticonsPref(bool expanded) {
    return UserPreferencesUI().useBlockiesIdenticons.builder(
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

  /*
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
   */

  Widget _identiconOptions(bool useBlockies) {
    final pref = UserPreferencesUI().useBlockiesIdenticons;
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
      expandedContent: _buildContractVersionOptions(),
      expandedHeight: available!.length * 54.0,
      textStyle: _textStyle,
    );
  }

  Widget _buildContractVersionOptions() {
    if (widget.selectContractVersion == null) {
      return Container();
    }
    return _contractVersionOptions(
      context: context,
      available: widget.contractVersionsAvailable!,
      selected: widget.contractVersionSelected!,
      select: widget.selectContractVersion!,
      textStyle: _textStyle,
    );
  }

  static Widget _contractVersionOptions({
    required BuildContext context,
    required Set<int> available,
    required int selected,
    required void Function(int version) select,
    required TextStyle textStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _contractVersionOptionsMenuItems(
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

  static List<PopupMenuEntry> _contractVersionOptionsMenuItems({
    required BuildContext context,
    required Set<int> available,
    required int selected,
    required void Function(int version) select,
    required TextStyle textStyle,
  }) {
    List<PopupMenuItem> list = [];
    if (available.contains(0)) {
      list.add(
        OrchidPopupMenuItemUtils.listMenuItem(
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
        OrchidPopupMenuItemUtils.listMenuItem(
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

  static List<PopupMenuEntry> _viewContractLinkMenuItems({
    required BuildContext context,
    required Set<int> available,
    required int selected,
    required TextStyle textStyle,
  }) {
    assert(selected < 2);
    List<PopupMenuItem> list = [];
    list.add(
      OrchidPopupMenuItemUtils.listMenuItem(
        context: context,
        textStyle: textStyle,
        selected: false,
        body: Row(
          children: [
            Icon(Icons.launch, color: Colors.white),
            Text(context.s.viewContractOnEtherscan, style: textStyle).left(12),
          ],
        ),
        onTap: () {
          launchUrlString(selected == 1
              ? OrchidUrls.contractV1EtherscanUrl
              : OrchidUrls.contractV0EtherscanUrl);
        },
      ),
    );
    list.add(
      OrchidPopupMenuItemUtils.listMenuItem(
        context: context,
        textStyle: textStyle,
        selected: false,
        body: Row(
          children: [
            Icon(Icons.launch, color: Colors.white),
            Text(context.s.viewContractOnGithub, style: textStyle).left(12),
          ],
        ),
        onTap: () {
          launchUrlString(selected == 1
              ? OrchidUrls.contractV1GithubUrl
              : OrchidUrls.contractV0GithubUrl);
        },
      ),
    );
    return list;
  }

  PopupMenuItem _listMenuItem({
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return OrchidPopupMenuItemUtils.listMenuItem(
      context: context,
      selected: selected,
      title: title,
      onTap: onTap,
      textStyle: _textStyle,
    );
  }
}
