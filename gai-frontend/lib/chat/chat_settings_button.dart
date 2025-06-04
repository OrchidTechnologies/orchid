import 'package:flutter/services.dart';
import 'package:orchid/chat/identicon_options_menu_item.dart';
import 'package:orchid/chat/provider_management_dialog.dart';
import 'package:orchid/chat/provider_manager.dart';
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
  final VoidCallback onExportState;
  final VoidCallback onImportState;
  final String? authToken;
  final String? inferenceUrl;

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
    required this.onExportState,
    required this.onImportState,
    this.authToken,
    this.inferenceUrl,
  }) : super(key: key);

  @override
  State<ChatSettingsButton> createState() => _ChatSettingsButtonState();
}

class _ChatSettingsButtonState extends State<ChatSettingsButton> {
  final _width = 273.0;
  final _height = 50.0;
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied to clipboard')),
      );
    }
  }

  List<PopupMenuEntry<dynamic>> _buildInferenceInfo() {
    if (widget.authToken == null || widget.inferenceUrl == null) {
      return [];
    }

    return [
      const PopupMenuDivider(height: 1.0),
      PopupMenuItem<String>(
        height: _height,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text('Inference Connection', style: _textStyle),
            children: [
              ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Auth Token:', style: TextStyle(color: Colors.white)),
                    Text(
                      widget.authToken!,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: () => _copyToClipboard(widget.authToken!, 'Auth token'),
                      child: const Text('Copy Token', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Inference URL:', style: TextStyle(color: Colors.white)),
                    Text(
                      widget.inferenceUrl!,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: () => _copyToClipboard(widget.inferenceUrl!, 'Inference URL'),
                      child: const Text('Copy URL', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final buildCommit = const String.fromEnvironment('build_commit', defaultValue: '...');
    final githubUrl = 'https://github.com/OrchidTechnologies/orchid/tree/$buildCommit/web-ethereum/dapp2';

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

          // Export state
          PopupMenuItem<String>(
            onTap: widget.onExportState,
            height: _height,
            child: SizedBox(
              width: _width,
              child: Row(
                children: [
                  const Icon(Icons.download, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text("Export Session", style: _textStyle),
                ],
              ),
            ),
          ),

          // Import state
          PopupMenuItem<String>(
            onTap: widget.onImportState,
            height: _height,
            child: SizedBox(
              width: _width,
              child: Row(
                children: [
                  const Icon(Icons.upload, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text("Import Session", style: _textStyle),
                ],
              ),
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

          // scripts
          SubmenuPopopMenuItemBuilder<String>(
            builder: (bool expanded) => ScriptsMenuItem(
              height: _height,
              width: _width,
              expanded: expanded,
              textStyle: _textStyle,
              editScript: () {
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
          
          // Tool Providers Management
          PopupMenuItem<String>(
            onTap: () {
              // Need to use Future.delayed because we can't show a dialog during onTap callback
              Future.delayed(Duration.zero, () {
                showDialog(
                  context: context,
                  builder: (context) => const ProviderManagementDialog(),
                );
              });
            },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text("Manage Tool Providers", style: _textStyle),
            ),
          ),

          // Inference connection info
          ..._buildInferenceInfo(),

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
}
