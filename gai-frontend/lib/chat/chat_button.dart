import 'package:orchid/orchid/orchid.dart';

class ChatButton extends StatelessWidget {
  const ChatButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 40,
  });

  final String text;
  final VoidCallback onPressed;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: FilledButton(
        style: TextButton.styleFrom(
          backgroundColor: OrchidColors.new_purple,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(text).button.white,
      ),
    );
  }
}

class OutlinedChatButton extends StatelessWidget {
  const OutlinedChatButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 40,
  });

  final String text;
  final VoidCallback onPressed;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(text).button.white,
      ),
    );
  }
}
