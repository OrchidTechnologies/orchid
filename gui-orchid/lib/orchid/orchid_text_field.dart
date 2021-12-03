import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

/// A styled text field with an optional custom trailing component.
class OrchidTextField extends StatelessWidget {
  final String hintText;
  final Widget trailing;
  final TextEditingController controller;
  final bool obscureText;
  final int maxLines;

  // If enabled the text field is editable
  final bool enabled;

  // If readOnly the text is displayed without the text field decoration
  final bool readOnly;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  final bool numeric;
  final double height;

  final VoidCallback onClear;

  OrchidTextField({
    this.hintText,
    this.trailing,
    this.controller,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.padding,
    this.margin,
    this.numeric = false,
    this.height = 56,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    var textStyle = OrchidText.body2.copyWith(height: 1.5);
    var hasValue = controller.text != '';
    return Container(
        height: height,
        margin: margin ??
            (readOnly ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 20)),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  enabled: enabled,
                  style: textStyle,
                  obscureText: obscureText,
                  controller: controller,
                  autocorrect: false,
                  textAlign: TextAlign.left,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: maxLines,
                  onChanged: null,
                  focusNode: null,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(
                        top: 24, bottom: 20, left: 16, right: 16),
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: textStyle.copyWith(
                        color: Colors.white.withOpacity(0.3)),
                    enabledBorder: textFieldEnabledBorder,
                    focusedBorder: textFieldFocusedBorder,
                    suffixIcon: hasValue
                        ? IconButton(
                            onPressed: onClear ?? controller.clear,
                            icon: Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Icon(Icons.clear,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 20),
                            ),
                          )
                        : null,
                  ),
                  cursorColor: Colors.white,
                  keyboardType: numeric
                      ? TextInputType.numberWithOptions(decimal: true)
                      : null,
                  inputFormatters: numeric
                      ? <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ]
                      : null,
                ),
              ),
            ),
            trailing != null ? trailing : Container(),
          ],
        ));
  }

  static var textFieldEnabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: Colors.white));

  static var textFieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      width: 2,
      // color: Color(0xffFC7EFF),
      color: OrchidColors.tappable,
    ),
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
