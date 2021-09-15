import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

import 'formatting.dart';

/// A rounded rectangle text button.
class RoundedRectButton extends StatelessWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Icon icon;
  final double elevation;

  const RoundedRectButton({
    Key key,
    @required this.text,
    @required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.elevation,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      elevation: elevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24))),
      child: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon ?? Container(),
            icon != null ? padx(14) : Container(),
            Padding(
              padding:
                  const EdgeInsets.only(top: 8, bottom: 8, left: 24, right: 24),
              child: Text(text,
                  style: style ??
                      OrchidText.button.copyWith(
                          color: textColor ?? OrchidText.button.color)),
            ),
            if (icon != null) padx(8)
          ],
        ),
      ),
      color: backgroundColor ?? OrchidColors.purple_bright,
      disabledColor: Colors.grey,
      onPressed: onPressed,
    );
  }
}

/// A round image button with a separate text subtitle positioned below it.
class RoundTitledRaisedImageButton extends StatelessWidget {
  final String title;
  final String imageName;
  final Icon icon;
  final VoidCallback onPressed;
  final double padding;

  const RoundTitledRaisedImageButton({
    Key key,
    @required this.title,
    this.imageName,
    @required this.onPressed,
    this.icon,
    this.padding = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RaisedButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.all(padding),
          color: OrchidColors.purple_ffb88dfc,
          child: Column(
            children: <Widget>[
              icon ??
                  Image.asset(imageName,
                      color: Colors.black, width: 40, height: 40),
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
              color: OrchidColors.purple_ffb88dfc),
        )
      ],
    );
  }
}

/// A flat Text button used as a control for e.g. "NEXT" and "DONE".
class TextControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final TextAlign alignment;
  final Color color;

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
  final String text;
  final TextAlign alignment;
  final Color color;

  LinkStyleTextButton(
    this.text, {
    this.alignment = TextAlign.center,
    this.onPressed,
    this.color = AppColors.grey_3,
  });

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
    S s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: TextButton(
          child: Text(
            s.save,
            style: OrchidText.title.copyWith(
                color: isValid ? OrchidColors.active : OrchidColors.inactive,
                height: 2.0),
          ),
          onPressed: isValid ? onPressed : null),
    );
  }
}

/// A rounded button comprising a title and trailing icon,
/// as used in the scan/paste dialog.
class TitleIconButton extends StatelessWidget {
  final String text;
  final Widget trailing;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onPressed;
  final double spacing;

  const TitleIconButton({
    Key key,
    @required this.text,
    @required this.trailing,
    @required this.textColor,
    @required this.backgroundColor,
    this.borderColor,
    @required this.onPressed,
    this.spacing = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      color: backgroundColor,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              color: borderColor ?? backgroundColor,
              width: 1,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
        child: Row(
          children: <Widget>[
            AppText.body(
                text: text,
                color: textColor,
                letterSpacing: 1.25,
                lineHeight: 1.14),
            padx(spacing),
            trailing
          ],
        ),
      ),
    );
  }
}

class CopyTextButton extends StatelessWidget {
  const CopyTextButton({
    Key key,
    @required this.copyText,
  }) : super(key: key);

  final String copyText;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RoundedRectButton(
            backgroundColor: Colors.deepPurple,
            textColor: Colors.white,
            text: s.copy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyText));
            }),
      ],
    );
  }
}
