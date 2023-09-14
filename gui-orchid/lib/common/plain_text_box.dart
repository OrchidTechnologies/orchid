import 'package:flutter/material.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'app_colors.dart';

class PlainTextBox extends StatelessWidget {
  const PlainTextBox({
    Key? key,
    required String text,
  })  : _text = text,
        super(key: key);

  final String _text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 32),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          border: Border.all(width: 1.0, color: AppColors.neutral_5),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            scrollbarTheme: ScrollbarThemeData(
              thumbColor:
                  MaterialStateProperty.all(Colors.white.withOpacity(0.4)),
            ),
          ),
          child: SingleChildScrollView(
            reverse: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  _text,
                  textAlign: TextAlign.left,
                  style: AppText.logStyle.copyWith(fontSize: 10).white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
