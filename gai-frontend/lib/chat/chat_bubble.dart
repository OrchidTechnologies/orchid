import 'package:orchid/orchid/orchid.dart';
import 'chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.debugMode,
  });

  final ChatMessage message;
  final bool debugMode;

  @override
  Widget build(BuildContext context) {
    ChatMessageSource src = message.source;

    List<Color> msgBubbleColor(ChatMessageSource src) {
      if (src == ChatMessageSource.client) {
        return <Color>[
          const Color(0xff52319c),
          const Color(0xff3b146a),
        ];
      } else {
        return <Color>[
          const Color(0xff005965),
          OrchidColors.dark_ff3a3149,
        ];
      }
    }

    if (src == ChatMessageSource.system || src == ChatMessageSource.internal) {
      if (!debugMode && src == ChatMessageSource.internal) {
        return Container();
      }

      return Center(
        child: Column(
          children: <Widget>[
            Text(
              message.message,
              style: src == ChatMessageSource.system
                  ? OrchidText.normal_14
                  : OrchidText.normal_14.grey,
            ),
            const SizedBox(height: 2),
          ],
        ),
      );
    }

    return Align(
      alignment: src == ChatMessageSource.provider
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: SizedBox(
        width: 0.6 * 800, //MediaQuery.of(context).size.width * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: _chatSourceText(message),
//              child: Text(src == ChatMessageSource.provider ? 'Chat' : 'You',
//                  style: OrchidText.normal_14),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      width: 0.6 * 800,
                      // MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: msgBubbleColor(message.source),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.6 * 800,
                    // MediaQuery.of(context).size.width * 0.6,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(message.message,
                        style: OrchidText.medium_20_050),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            if (src == ChatMessageSource.provider) ...[
              Text(
                style: OrchidText.normal_14,
                'model: ${message.metadata?["model"]}   usage: ${message.metadata?["usage"]}',
              )
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _chatSourceText(ChatMessage msg) {
    final String srcText;
    if (msg.sourceName.isEmpty) {
      srcText = msg.source == ChatMessageSource.provider ? 'Chat' : 'You';
    } else {
      srcText = msg.sourceName;
    }
    return Text(
      srcText,
      style: OrchidText.normal_14,
    );
  }
}

