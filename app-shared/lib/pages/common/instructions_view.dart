import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text.dart';

/// Instructional text with vertically arranged image, title, and body.
/// Optionally hides itself in landscape mode.
class InstructionsView extends StatelessWidget {
  final Image image;
  final String title;
  final String body;
  final bool hideInLandscape;

  const InstructionsView(
      {Key key,
      this.image,
      @required this.title,
      @required this.body,
      this.hideInLandscape = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Visibility(
          visible: orientation == Orientation.portrait,
          child: SafeArea(
              child: Column(
            children: <Widget>[
              Spacer(flex: 1),
              image ?? Container(),
              SizedBox(height: 20),
              AppText.header(
                  text: title,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 20.0),
              SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: AppText.body(
                      text: body,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.0,
                      color: AppColors.neutral_1),
                ),
              ),
              Spacer(flex: 1),
            ],
          )),
        );
      },
    );
  }
}
