import 'package:orchid/orchid/orchid.dart';

class DappErrorRow extends StatelessWidget {
  final String text;

  const DappErrorRow({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text).caption.error,
      ],
    );
  }
}
