// @dart=2.9
import 'package:orchid/orchid.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'orchid_text_field.dart';

/// The orchid text field with the standard labeled rounded rect.
class OrchidLabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget trailing;
  final String hintText;
  final bool error;
  final bool numeric;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const OrchidLabeledTextField({
    Key key,
    @required this.label,
    @required this.controller,
    this.hintText,
    this.trailing,
    this.onChanged,
    this.onClear,
    this.error = false,
    this.numeric = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedRect(
      backgroundColor: Colors.white.withOpacity(0.1),
      borderColor: error ? OrchidColors.status_red : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label).body1.left(18).top(16),
          OrchidTextField(
            numeric: numeric,
            border: false,
            hintText: hintText,
            style: OrchidText.title.copyWith(fontSize: 22, height: 1.0),
            controller: controller,
            trailing: trailing,
            contentPadding: EdgeInsets.only(top: 8, bottom: 14, left: 16, right: 16),
            onChanged: onChanged,
            onClear: onClear,
          ),
        ],
      ),
    );
  }
}
