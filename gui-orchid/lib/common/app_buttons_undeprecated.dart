import 'package:flutter/material.dart';

class FlatButtonDeprecated extends FlatButton {
  const FlatButtonDeprecated({
    Key key,
    Widget child,
    VoidCallback onPressed,
    ShapeBorder shape,
    Color color,
    EdgeInsets padding,
  }) : super(
          key: key,
          child: child,
          onPressed: onPressed,
          shape: shape,
          color: color,
          padding: padding,
        );
}

class RaisedButtonDeprecated extends RaisedButton {
  const RaisedButtonDeprecated({
    Key key,
    Widget child,
    VoidCallback onPressed,
    ShapeBorder shape,
    Color color,
    EdgeInsets padding,
    double elevation,
    MaterialTapTargetSize materialTapTargetSize,
    Color disabledColor,
  }) : super(
          key: key,
          child: child,
          onPressed: onPressed,
          shape: shape,
          color: color,
          padding: padding,
          elevation: elevation,
          materialTapTargetSize: materialTapTargetSize,
          disabledColor: disabledColor,
        );
}
