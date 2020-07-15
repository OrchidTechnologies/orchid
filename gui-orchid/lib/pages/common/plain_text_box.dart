import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/pages/app_text.dart';
import '../app_colors.dart';

class PlainTextBox extends StatelessWidget {
  const PlainTextBox({
    Key key,
    @required String text,
  }) : _text = text, super(key: key);

  final String _text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
            left: 8, right: 8, top: 16, bottom: 32),
        child: Container(
          child: Scrollbar(
            child: SingleChildScrollView(
              reverse: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _text,
                  textAlign: TextAlign.left,
                  style: AppText.logStyle.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            border:
            Border.all(width: 2.0, color: AppColors.neutral_5),
          ),
        ),
      ),
    );
  }
}
