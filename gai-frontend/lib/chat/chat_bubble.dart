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

    // Constants for consistent spacing
    const double iconSize = 16.0;
    const double iconSpacing = 8.0;
    const double iconTotalWidth = iconSize + iconSpacing;

    if (src == ChatMessageSource.notice || src == ChatMessageSource.internal || src == ChatMessageSource.system) {
      // Don't show internal messages unless in debug mode
      if (!debugMode && src == ChatMessageSource.internal) {
        return Container();
      }
      
      // System messages are for LLMs only, not for display
      if (src == ChatMessageSource.system) {
        return Container();
      }

      return Center(
        child: Column(
          children: <Widget>[
            SelectableText(
              message.message,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 14,
                // 16px equivalent
                height: 1.0,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 0.6 * 800),
        child: Column(
          crossAxisAlignment: src == ChatMessageSource.provider
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: <Widget>[
            // Header row with icon and name for both provider and user
            Row(
              mainAxisAlignment: src == ChatMessageSource.provider
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (src == ChatMessageSource.provider) ...[
                  const Icon(
                    Icons.stars_rounded,
                    color: OrchidColors.blue_highlight,
                    size: iconSize,
                  ),
                  const SizedBox(width: iconSpacing),
                  Text(
                    message.displayName ?? 'Chat',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 14,
                      // 16px equivalent
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                      color: OrchidColors.blue_highlight,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'You',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 14,
                      // 16px equivalent
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                      color: OrchidColors.blue_highlight,
                    ),
                  ),
                  const SizedBox(width: iconSpacing),
                  const Icon(
                    Icons.account_circle_rounded,
                    color: OrchidColors.blue_highlight,
                    size: iconSize,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Message content with padding for provider messages
            if (src == ChatMessageSource.provider)
              Padding(
                padding: const EdgeInsets.only(left: iconTotalWidth),
                child: SelectableText(
                  message.message,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 20,
                    // 20px design spec
                    height: 1.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  message.message,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 20,
                    // 20px design spec
                    height: 1.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            // Usage metadata for provider messages
            if (src == ChatMessageSource.provider) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: iconTotalWidth),
                child: SelectableText(
                  message.formatUsage(),
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 14,
                    // 16px equivalent
                    height: 1.0,
                    fontWeight: FontWeight.normal,
                    color: OrchidColors.purpleCaption,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
