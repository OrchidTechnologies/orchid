import 'package:orchid/chat/api/user_preferences_chat.dart';
import 'package:orchid/chat/scripting/chat_scripting.dart';
import 'package:orchid/chat/scripting/code_viewer/script_code_box.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';

class UserScriptDialog extends StatefulWidget {
  const UserScriptDialog({
    super.key,
  });

  static void show(BuildContext context) {
    AppDialogs.showAppDialog(
      context: context,
      showActions: false,
      contentPadding: EdgeInsets.zero,
      body: const UserScriptDialog(),
    );
  }

  static const exampleScript = '''
/// This is an example user script that demonstrates how to use the chat API to interact with the chat. 
function onUserPrompt(userPrompt) {
    (async () => {
        // Log a system message to the chat
        chatSystemMessage('Extension: Example');
        
        // Add the user prompt to the chat
        let userMessage = new ChatMessage(ChatMessageSource.CLIENT, userPrompt, {});
        addChatMessage(userMessage);
        
        // Send it to the first user-selected model
        const modelId = getUserSelectedModels()[0].id;
        addChatMessage(await sendMessagesToModel([userMessage], modelId, null));
    })();
}
''';

  @override
  State<UserScriptDialog> createState() => _UserScriptDialogState();
}

class _UserScriptDialogState extends State<UserScriptDialog> {
  String? savedScript;
  String? editedScript;

  bool get hasUnsavedChanges {
    return editedScript != null && (savedScript != editedScript);
  }

  @override
  void initState() {
    super.initState();

    // Default the script on load once
    savedScript = UserPreferencesScripts().userScript.get();
    if (savedScript == null) {
      editedScript = UserScriptDialog.exampleScript;
    }

    UserPreferencesScripts().userScript.stream().listen((script) {
      // guard against the case where this widget is disposed before the stream emits
      if (!mounted) {
        return;
      }

      if (script != null) {
        setState(() {
          savedScript = script;
          editedScript = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the width of the dialog
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width < 500 ? width - 80 : width * 0.7;
    final height = MediaQuery.of(context).size.height;
    final double dialogHeight = height < 500 ? height - 80 : height * 0.7;

    return SizedBox(
      child: OrchidTitledPanel(
        titleText: 'User Script',
        highlight: false,
        opaque: true,
        onDismiss: _dismiss,
        body: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: UserScriptEditor(
                    language: 'typescript',
                    theme: 'a11y-dark',
                    // Allow the edited script to be initialized if no saved script
                    initialScript: savedScript ?? editedScript,
                    onScriptChanged: (script) {
                      log('User script changed: $script');
                      setState(() {
                        editedScript = script;
                      });
                    },
                  ),
                ).pad(24),
              ),

              // Save button
              OrchidActionButton(
                text: 'Save',
                onPressed: hasUnsavedChanges
                    ? () {
                        final emptyScript =
                            editedScript?.trim().isEmpty ?? false;
                        if (emptyScript) {
                          UserPreferencesScripts().userScript.clear();
                          UserPreferencesScripts().userScriptEnabled.set(false);
                        } else {
                          UserPreferencesScripts().userScript.set(editedScript?.trim());
                          UserPreferencesScripts().userScriptEnabled.set(true);
                          savedScript = editedScript;
                          ChatScripting.instance.setScript(editedScript!);
                        }
                        _dismiss();
                      }
                    : null,
              ).bottom(24),
            ],
          ),
        ),
      ).show,
    );
  }

  void _dismiss() {
    Navigator.pop(context);
  }
}
