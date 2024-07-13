import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_item_utils.dart';
import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../orchid/menu/orchid_popup_menu_button.dart';
import 'chat_button.dart';

class ChatModelButton extends StatefulWidget {
//  final bool debugMode;
//  final VoidCallback onDebugModeChanged;
  final updateModel;
  final Map<String, Map<String, String>> providers;

  const ChatModelButton({
    Key? key,
//    required this.debugMode,
//    required this.onDebugModeChanged
    required this.providers,
    required this.updateModel,
  }) : super(key: key);

  @override
  State<ChatModelButton> createState() => _ChatModelButtonState();
}

class _ChatModelButtonState extends State<ChatModelButton> {
  final _width = 273.0;
  final _height = 50.0;
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    return OrchidPopupMenuButton<dynamic>(
      width: 80,
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
        
        return widget.providers.entries.map((entry) {
          final providerId = entry.key;
          final providerName = entry.value['name'] ?? providerId;
          
          return PopupMenuItem<String>(
            onTap: () { widget.updateModel(providerId); },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text(providerName, style: _textStyle),
            ),
          );
        }).toList();
      },
/*
      itemBuilder: (itemBuilderContext) {
        setState(() {
          _buttonSelected = true;
        });

        const div = PopupMenuDivider(height: 1.0);
        return [
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('gpt4');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('GPT-4', style: _textStyle),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('gpt4o');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('GPT-4o', style: _textStyle),
            ),
          ),
//          div,
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('mistral');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('Mistral 7B', style: _textStyle),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('mixtral-8x22b');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('Mixtral 8x22b', style: _textStyle),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('gemini');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('Gemini 1.5', style: _textStyle),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('claude-3');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('Claude 3 Opus', style: _textStyle),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () { widget.updateModel('claude35sonnet');  },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text('Claude 3.5 Sonnet', style: _textStyle),
            ),
          ),
        ];
      },
*/

    /*
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
              width: 80, height: 20, child: Text('Model'))),
*/
//      child: SizedBox(
//             width: 120, height: 20, child: Text('Model', style: _textStyle).white),
      child: Align(
               alignment: Alignment.center,
               child: Text('Model', textAlign: TextAlign.center).button.white,
             ),
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
