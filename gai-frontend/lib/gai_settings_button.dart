import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_item_utils.dart';
import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../orchid/menu/orchid_popup_menu_button.dart';

class GAISettingsButton extends StatefulWidget {
  final bool debugMode;
  final VoidCallback onDebugModeChanged;

  const GAISettingsButton({
    Key? key,
    required this.debugMode,
    required this.onDebugModeChanged,
  }) : super(key: key);

  @override
  State<GAISettingsButton> createState() => _GAISettingsButtonState();
}

class _GAISettingsButtonState extends State<GAISettingsButton> {
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
        setState(() {
          _buttonSelected = true;
        });

        const div = PopupMenuDivider(height: 1.0);
        return [
          // debug mode
          PopupMenuItem<String>(
            onTap: widget.onDebugModeChanged,
            height: _height,
            child: SizedBox(
              width: _width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Debug Mode", style: _textStyle),
                  Icon(
                    widget.debugMode
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          div,
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildIdenticonsPref,
          ),
          div,
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildLanguagePref,
          ),
          div,
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
          div,
          // dapp version item
          _listMenuItem(
            selected: false,
            title: 'Version: ' + buildCommit,
            onTap: () async {
              launchUrlString(githubUrl);
            },
          ),
        ];
      },
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
              width: 20, height: 20, child: OrchidAsset.svg.settings_gear)),
    );
  }

  Future _openLicensePage(BuildContext context) {
    // TODO:
    return Future.delayed(millis(100), () async {});
    // return Navigator.push(context,
    //     MaterialPageRoute(builder: (BuildContext context) {
    //   return OpenSourcePage();
    // }));
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
