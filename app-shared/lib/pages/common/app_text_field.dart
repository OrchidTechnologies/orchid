import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

/// A styled text field with an optional custom trailing component.
class AppTextField extends StatelessWidget {
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

  AppTextField(
      {this.hintText,
      this.trailing,
      this.controller,
      this.obscureText = false,
      this.maxLines = 1,
      this.enabled = true,
      this.readOnly = false,
      this.padding,
      this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: readOnly ? BoxDecoration() : textFieldEnabledDecoration,
        height: 56,
        margin: margin ??
            (readOnly ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 20)),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  enabled: enabled,
                  obscureText: obscureText,
                  controller: controller,
                  autocorrect: false,
                  textAlign: TextAlign.left,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: AppText.textHintStyle),
                  onChanged: null,
                  focusNode: null,
                ),
              ),
            ),
            trailing != null ? trailing : Container(),
          ],
        ));
  }

  static BoxDecoration textFieldEnabledDecoration = BoxDecoration(
      color: AppColors.neutral_7,
      borderRadius: BorderRadius.circular(4.0),
      border: Border.all(color: AppColors.neutral_5, width: 2.0));

  static BoxDecoration textFieldFocusedDecoration = BoxDecoration(
      color: AppColors.neutral_7,
      borderRadius: BorderRadius.circular(4.0),
      border: Border.all(color: AppColors.teal_4, width: 3.0));
}

/// A text field with an internal label (placeholder) that moves above the text
/// entry area on focus.  This differs from the standard material TextField in that
/// the label text does not move into the border but remains inside it.
class AppLabeledTextField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType textInputType;
  final Widget trailing;
  final FormFieldValidator<String> validator;
  final int maxLines;

  AppLabeledTextField(
      {this.labelText,
      this.controller,
      this.obscureText = false,
      this.trailing,
      this.hintText,
      this.textInputType,
      this.validator,
      this.maxLines = 1});

  @override
  _AppLabeledTextFieldState createState() => _AppLabeledTextFieldState();
}

class _AppLabeledTextFieldState extends State<AppLabeledTextField> {
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Note: Is there some way to do this directly with a builder?
    _focusNode.addListener(() {
      setState(() {}); // Update textfield decoration on focus change.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 56, // this positions the floating label text too close to the input text
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: 16, right: 16),
      decoration: _focusNode.hasFocus
          ? AppTextField.textFieldFocusedDecoration
          : AppTextField.textFieldEnabledDecoration,
      child: TextFormField(
        style: AppText.textEntryStyle,
        controller: widget.controller,
        keyboardType: widget.textInputType,
        obscureText: widget.obscureText,
        validator: widget.validator,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
            border: InputBorder.none,
            labelText: widget.labelText,
            labelStyle: AppText.textLabelStyle,
            hintText: widget.hintText,
            suffix: widget.trailing),
        focusNode: _focusNode,
      ),
    );
  }
}

class AppPasswordField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;

  const AppPasswordField(
      {Key key, this.labelText, this.hintText, this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppLabeledTextField(
      labelText: labelText,
      hintText: hintText,
      controller: controller,
      obscureText: true,
      // TODO: This is causing overlfow on the page containing this widget for some reason.
      //trailing: Container(
      //margin: EdgeInsets.only(right: 13.0),
      //child: Image.asset("assets/images/visibility.png"))
    );
  }
}
