import 'package:orchid/orchid/orchid.dart';

class ChatButton extends StatelessWidget {
  const ChatButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
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

