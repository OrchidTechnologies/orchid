import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'app_colors.dart';
import 'app_text.dart';

class ConfigText extends StatelessWidget {
  final double height;
  final TextEditingController textController;
  final String hintText;

  const ConfigText({
    Key? key,
    required this.height,
    required this.textController,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextFormField(
          autocorrect: false,
          autofocus: false,
          smartQuotesType: SmartQuotesType.disabled,
          smartDashesType: SmartDashesType.disabled,
          keyboardType: TextInputType.multiline,
          style: OrchidText.caption,
          controller: textController,
          maxLines: 99999,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: OrchidText.caption,
            border: InputBorder.none,
            labelStyle: AppText.textLabelStyle,
          ),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          border: Border.all(width: 2.0, color: AppColors.neutral_5),
        ),
      ),
    );
  }
}

class ConfigLabel extends StatelessWidget {
  final String text;

  const ConfigLabel({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(text + ':',
            style: AppText.textLabelStyle
                .copyWith(fontSize: 20).white));
  }
}

