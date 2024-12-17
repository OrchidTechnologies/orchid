import 'package:orchid/chat/identicon_options_menu_item.dart';
import 'package:orchid/chat/scripting/code_viewer/scripts_menu_item.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_item_utils.dart';
import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../orchid/menu/orchid_popup_menu_button.dart';

class ChatSettingsButton extends StatefulWidget {
  final bool debugMode;
  final bool multiSelectMode;
  final bool partyMode;
  final VoidCallback onDebugModeChanged;
  final VoidCallback onMultiSelectModeChanged;
  final VoidCallback onPartyModeChanged;
  final VoidCallback onClearChat;
  final VoidCallback editUserScript;

  const ChatSettingsButton({
    Key? key,
    required this.debugMode,
    required this.multiSelectMode,
    required this.partyMode,
    required this.onDebugModeChanged,
    required this.onMultiSelectModeChanged,
    required this.onPartyModeChanged,
    required this.onClearChat,
    required this.editUserScript,
  }) : super(key: key);

  @override
  State<ChatSettingsButton> createState() => _ChatSettingsButtonState();
}

class _ChatSettingsButtonState extends State<ChatSettingsButton> {
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
      width: 30,
      height: 30,
      selected: _buttonSelected,
      backgroundColor: Colors.transparent,
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
          // Clear chat
          PopupMenuItem<String>(
            onTap: widget.onClearChat,
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text("Clear Chat", style: _textStyle),
            ),
          ),
          div,

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

          // multi-select mode
          PopupMenuItem<String>(
            onTap: widget.onMultiSelectModeChanged,
            height: _height,
            child: SizedBox(
              width: _width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Multi-Model Mode", style: _textStyle),
                  Icon(
                    widget.multiSelectMode
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          div,

          /*
          // party mode
          PopupMenuItem<String>(
            onTap: widget.onPartyModeChanged,
            height: _height,
            child: SizedBox(
              width: _width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Party Mode", style: _textStyle),
                  Icon(
                    widget.partyMode
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          div,
           */

          // scripts
          SubmenuPopopMenuItemBuilder<String>(
            builder: (bool expanded) => ScriptsMenuItem(
              height: _height,
              width: _width,
              expanded: expanded,
              textStyle: _textStyle,
              editScript: () {
                log('edit script');
                Navigator.pop(context);
                widget.editUserScript();
              },
            ),
          ),
          div,

          // identicon style menu
          SubmenuPopopMenuItemBuilder<String>(
            builder: (bool expanded) => IdenticonOptionsMenuItem(
              expanded: expanded,
              textStyle: _textStyle,
            ),
          ),
          div,

          // build version
          PopupMenuItem<String>(
            onTap: () async {
              launchUrlString(githubUrl);
            },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('Version: $buildCommit', style: _textStyle),
            ),
          ),
        ];
      },

      // settings icon
      child: SizedBox(
        width: 30,
        height: 30,
        child: FittedBox(
          fit: BoxFit.contain,
          child: OrchidAsset.svg.settings_gear,
        ),
      ),
    );
  }

  /*
  Future _openLicensePage(BuildContext context) {
    // TODO:
    return Future.delayed(millis(100), () async {});
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
   */

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
        .cast<PopupMenuEntry>()
        .separatedWith(
          const PopupMenuDivider(height: 1.0),
        );

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
