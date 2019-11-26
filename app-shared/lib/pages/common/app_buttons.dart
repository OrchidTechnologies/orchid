import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

/// A rounded rectangle raised text button.
class RoundedRectRaisedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Icon icon;

  const RoundedRectRaisedButton({
    Key key,
    @required this.text,
    @required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
      child: icon ?? AppText.body(
          text: text,
          color: textColor ?? AppColors.text_light,
          letterSpacing: 1.25,
          lineHeight: 1.14),
      color: backgroundColor ?? AppColors.purple_3,
      onPressed: onPressed,
    );
  }
}

/// A round image button with a text subtitle.
class RoundTitledRaisedButton extends StatelessWidget {
  const RoundTitledRaisedButton({
    Key key,
    @required this.title,
    @required this.imageName,
    @required this.onPressed,
  }) : super(key: key);

  final String title;
  final String imageName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RaisedButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.all(0),
          color: AppColors.purple_3,
          child: Column(
            children: <Widget>[
              Image.asset(imageName,
                  color: AppColors.white, width: 40, height: 40),
            ],
          ),
          onPressed: onPressed,
          shape: CircleBorder(),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
              //height: 1.333,
              fontSize: 13,
              color: AppColors.purple_3),
        )
      ],
    );
  }
}

/// A flat Text button used as a control for e.g. "NEXT" and "DONE".
class TextControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  String text;
  TextAlign alignment;
  Color color;

  TextControlButton(this.text,
      {this.alignment = TextAlign.left,
      this.onPressed,
      this.color = AppColors.grey_3});

  @override
  Widget build(BuildContext context) {
    var textStyle =
        AppText.buttonStyle.copyWith(color: color, letterSpacing: 1.25);
    var textChild = Text(text, textAlign: alignment, style: textStyle);

    return FlatButton(
      onPressed: onPressed,
      child: textChild,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }
}

/// A flat Text button that is styled like a web link.
class LinkStyleTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  String text;
  TextAlign alignment;
  Color color;

  LinkStyleTextButton(this.text,
      {this.alignment = TextAlign.center,
      this.onPressed,
      this.color = AppColors.grey_3});

  @override
  Widget build(BuildContext context) {
    var textStyle = AppText.buttonStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        decoration: TextDecoration.underline);
    var textChild = Text(text, textAlign: alignment, style: textStyle);

    return FlatButton(
      onPressed: onPressed,
      child: textChild,
    );
  }
}

class SaveActionButton extends StatelessWidget {
  const SaveActionButton({
    Key key,
    @required this.isValid,
    @required this.onPressed,
  }) : super(key: key);

  final bool isValid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
        child: Text(
          "Save",
          style: AppText.actionButtonStyle.copyWith(
              // TODO: We need to get the TitledPage to publish colors on the context (theme)
              color: isValid ? Colors.white : Colors.white.withOpacity(0.4)),
        ),
        onPressed: isValid ? onPressed : null);
  }
}
