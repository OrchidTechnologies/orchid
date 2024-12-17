import 'package:orchid/chat/api/user_preferences_chat.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';

class ScriptsMenuItem extends StatelessWidget {
  final double height;
  final double width;
  final TextStyle _textStyle;
  final bool expanded;
  final VoidCallback editScript;

  const ScriptsMenuItem({
    super.key,
    required TextStyle textStyle,
    required this.expanded,
    required this.height,
    required this.width,
    required this.editScript,
  }) : _textStyle = textStyle;

  @override
  Widget build(BuildContext context) {
    return UserPreferencesScripts().userScriptEnabled.builder(
      (bool? scriptEnabled) {
        if (scriptEnabled == null) {
          return Container();
        }
        final scriptInitialized =
            UserPreferencesScripts().userScript.get() != null;
        return ExpandingPopupMenuItem(
          expanded: expanded,
          title: "User Script",
          currentSelectionText:
              (!expanded ? (scriptEnabled ? "Enabled" : '') : ''),
          expandedContent: _scriptOptions(context, scriptEnabled),
          expandedHeight: (scriptInitialized ? 120 : height),
          textStyle: _textStyle,
        );
      },
    );
  }

  Widget _scriptOptions(BuildContext context, bool scriptEnabled) {
    final enabledPref = UserPreferencesScripts().userScriptEnabled;
    final script = UserPreferencesScripts().userScript.get();
    final bool hasScript = script != null && script.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // show one line of the script
        if (hasScript)
          Container(
            color: OrchidColors.dark_background,
            child: Text(
              script.trim().truncate(36),
              textAlign: TextAlign.left,
              maxLines: 1,
              style: AppText.logStyle.white,
            ).pad(4),
          ),

        // TODO: Make a checked item widget for this and backport to the other dapps
        // Script enabled checkbox
        if (hasScript)
          PopupMenuItem<String>(
            onTap: () {
              enabledPref.set(!scriptEnabled);
            },
            height: height,
            child: SizedBox(
              width: width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Enabled", style: _textStyle),
                  Icon(
                    scriptEnabled
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        // div,

        // Edit link
        Text(hasScript ? "Edit Script" : "Add Script").linkButton(
          onTapped: editScript,
          style: OrchidText.body1.blueHightlight,
        ),
      ],
    );
  }
}
