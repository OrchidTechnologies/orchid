import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/services.dart';

/// A styled text field with an optional custom trailing component.
class OrchidTextField extends StatelessWidget {
  final String? hintText;
  final Widget? trailing;
  final TextEditingController controller;
  final bool obscureText;
  final int maxLines;

  // If enabled the text field is editable
  final bool enabled;

  // If readOnly the text is displayed without the text field decoration
  final bool readOnly;

  final bool numeric;

  /// If numeric, whether to allow decimal values
  final bool decimal;

  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final bool border;
  final TextStyle? style;
  final EdgeInsets? contentPadding;
  final EdgeInsets? suffixIconPadding;
  final TextAlignVertical? textAlignVertical;
  final double? cursorHeight;

  OrchidTextField({
    required this.controller,
    this.hintText,
    this.trailing,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.numeric = false,
    this.decimal = true,
    this.onClear,
    this.onChanged,
    this.border = true,
    this.style,
    this.contentPadding,
    this.textAlignVertical,
    this.suffixIconPadding,
    this.cursorHeight,
  });

  @override
  Widget build(BuildContext context) {
    var textStyle = style ??
        TextStyle(
            fontFamily: "Baloo2",
            fontWeight: FontWeight.normal,
            color: Colors.white,
            fontSize: 16,
            height: 1.00,
            letterSpacing: 0.25);

    var hasValue = controller.text != '';

    final suffixIcon = hasValue && !readOnly
        ? IconButton(
            // cannot be null, this is the original default
            padding: suffixIconPadding ?? const EdgeInsets.all(8.0),
            onPressed: () {
              controller.clear();
              if (onClear != null) {
                onClear!();
              }
            },
            icon: Icon(
              Icons.clear,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ).right(4.0),
          )
        : null;

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            enabled: enabled,
            style: textStyle,
            obscureText: obscureText,
            controller: controller,
            autocorrect: false,
            textAlign: TextAlign.left,
            textAlignVertical: textAlignVertical ?? TextAlignVertical.bottom,
            cursorHeight: cursorHeight,
            maxLines: 1,
            onChanged: onChanged,
            focusNode: null,
            decoration: InputDecoration(
              // isDense: true,
              contentPadding: contentPadding ??
                  EdgeInsets.only(top: 19, bottom: 17, left: 16, right: 16),
              border: InputBorder.none,
              hintText: hintText,
              // hintStyle: textStyle.copyWith(color: Colors.white.withOpacity(0.3)),
              hintStyle: textStyle.inactive,
              enabledBorder: (border ? textFieldEnabledBorder : null),
              disabledBorder: (border ? textFieldDisabledBorder : null),
              focusedBorder: (border ? textFieldFocusedBorder : null),
              // suffix: suffixIcon,
              suffixIcon: suffixIcon,
            ),
            cursorColor: Colors.white,
            keyboardType: numeric
                ? TextInputType.numberWithOptions(decimal: decimal)
                : null,
            inputFormatters: numeric
                ? (decimal
                    ? <TextInputFormatter>[
                        // include comma as decimal separator
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ]
                    : <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ])
                : null,
          ),
        ),
        trailing != null ? trailing! : Container(),
      ],
    );
  }

  static var textFieldEnabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: Colors.white));

  static var textFieldDisabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: Colors.white.withOpacity(0.2)));

  static var textFieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(width: 2, color: OrchidColors.tappable),
  );

  static var textFieldErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(width: 2, color: OrchidColors.status_red),
  );

  // TODO: Remove
  static BoxDecoration textFieldEnabledDecoration = BoxDecoration(
      color: OrchidColors.dark_background,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: Colors.white, width: 2.0));

  // TODO: Remove
  static BoxDecoration textFieldFocusedDecoration = BoxDecoration(
      color: OrchidColors.dark_background,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: OrchidColors.purple_ffb88dfc, width: 3.0));
}
