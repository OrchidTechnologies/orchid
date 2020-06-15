import 'package:flutter/material.dart';
import 'package:orchid/api/notifications.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

/// Produce notification banners for various AppNotificationTypes.
class NotificationBannerFactory {
  /// Return the current notification banner or null if no banner should be shown.
  static current() {
    switch (AppNotifications().notification.value) {
      case AppNotificationType.None:
        return null;
      case AppNotificationType.InternetRequired:
        return _internetRequiredBanner();
    }
  }

  static NotificationBanner _internetRequiredBanner() {
    return NotificationBanner(
      title: 'No internet connection',
      titleColor: AppColors.warning_banner1,
      imageName: 'assets/images/error.png',
      trailingActionTitle: 'RETRY',
      trailingAction: () {},
    );
  }
}

/// A tile containing an image, title, and trailing button styled to
/// appear at the top of a page for notifications.
/// An optional progress bar may appear in the background.
class NotificationBanner extends StatefulWidget {
  final String title;
  final Color titleColor;
  final String imageName;
  final String trailingActionTitle;
  VoidCallback trailingAction;

  NotificationBanner({
    @required this.title,
    this.titleColor = Colors.white,
    this.imageName,
    this.trailingActionTitle,
    this.trailingAction,
  });

  @override
  _NotificationBannerState createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  double height;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 20, right: 0),
        alignment: Alignment.center,
        height: 40,
        color: AppColors.neutral_1,
        child: Row(
          children: <Widget>[
            widget.imageName != null
                ? Image(
                    color: widget.titleColor,
                    image: AssetImage(widget.imageName))
                : Container(),
            SizedBox(width: 10),
            Text(widget.title,
                style: AppText.bodyStyle
                    .copyWith(color: widget.titleColor, height: 1.0)),
            Spacer(),
            FlatButton(
              // TODO: How do we get rid of the internal padding in the FlatButton?
              //padding: EdgeInsets.all(0),
              //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //color: Colors.orange,
              child: Container(
                //color: Colors.green,
                child: Text(
                  widget.trailingActionTitle,
                  textAlign: TextAlign.right,
                  style: AppText.buttonStyle,
                ),
              ),
              onPressed: widget.trailingAction,
            ),
          ],
        ));
  }
}
