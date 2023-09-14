import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'orchid_text_field.dart';

/// The orchid text field with the standard labeled rounded rect.
class OrchidLabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget? trailing;
  final String? hintText;
  final bool error;
  final bool numeric;
  final bool decimal;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final EdgeInsets? contentPadding;
  final bool enabled;
  final Color? backgroundColor;

  const OrchidLabeledTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.hintText,
    this.trailing,
    this.onChanged,
    this.onClear,
    this.error = false,
    this.numeric = false,
    this.decimal = true,
    this.contentPadding,
    this.enabled = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedRect(
      backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.1),
      borderColor: error ? OrchidColors.status_red : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: enabled ? OrchidText.body1 : OrchidText.body1.inactive,
          ).left(18).top(16),
          OrchidTextField(
            enabled: enabled,
            numeric: numeric,
            decimal: decimal,
            border: false,
            hintText: hintText,
            style: OrchidText.title.copyWith(fontSize: 22, height: 1.0),
            controller: controller,
            trailing: trailing,
            contentPadding: contentPadding ??
                EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
            onChanged: onChanged,
            onClear: onClear,
          ),
        ],
      ),
    );
  }
}
