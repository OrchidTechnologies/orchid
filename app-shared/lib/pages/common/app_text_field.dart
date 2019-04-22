import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

/// A styled text field
class AppTextField extends StatelessWidget {
  String hintText;
  Widget trailing;
  TextEditingController controller;
  bool obscureText = false;

  AppTextField(
      {this.hintText,
      this.trailing,
      this.controller,
      this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: textFieldEnabledDecoration,
        height: 56,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  obscureText: obscureText,
                  controller: controller,
                  autocorrect: false,
                  textAlign: TextAlign.left,
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

  AppLabeledTextField(
      {@required this.labelText,
      this.controller,
      this.obscureText = false,
      this.trailing,
      this.hintText,
      this.textInputType, this.validator});

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
