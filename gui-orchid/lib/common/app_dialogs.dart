import 'package:orchid/orchid/orchid.dart';
import 'app_buttons_deprecated.dart';
import 'app_colors.dart';
import 'app_text.dart';

class AppDialogs {
  /// Show a styled Orchid app dialog with title, body, OK button, and optional link to settings.
  static Future<void> showAppDialog({
    required BuildContext context,
    String? title,
    String? bodyText,
    Widget? body,
    bool linkSettings = false,
    bool showActions = true,
    EdgeInsets? contentPadding,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // scrollable: true,
          backgroundColor: OrchidColors.dark_background,
          actionsPadding: showActions ? null : EdgeInsets.zero,
          // buttonPadding: EdgeInsets.zero,
          // titlePadding: EdgeInsets.zero,
          contentPadding: contentPadding,
          // insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0))),
          title: title != null ? Text(title, style: OrchidText.title) : null,
          content: body ?? Text(bodyText ?? '', style: OrchidText.body2),
          actions: <Widget>[
            if (linkSettings)
              FlatButtonDeprecated(
                child: Text(context.s.settingsButtonTitle, style: AppText.dialogButton),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            if (showActions)
              FlatButtonDeprecated(
                child: Text(context.s.ok,
                    style: OrchidText.button
                        .copyWith(color: OrchidColors.purple_bright)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    Widget? body,
    String? bodyText,
    String? cancelText,
    Color cancelColor = AppColors.purple_3,
    actionText,
    Color actionColor = AppColors.purple_3,
    VoidCallback? cancelAction,
    VoidCallback? commitAction,
    EdgeInsets? contentPadding,
    bool dark = false,
  }) {
    log("XXX: confirmation dialog show..");
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        S s = S.of(context)!;
        return AlertDialog(
          contentPadding: contentPadding,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          backgroundColor:
              dark ? OrchidColors.dark_background : OrchidColors.blue_highlight,
          title: titleWidget != null
              ? titleWidget
              : (title != null
                  ? Text(
                      title,
                      style: dark
                          ? OrchidText.subtitle.white
                          : OrchidText.subtitle.black,
                    )
                  : null),
          content: body ??
              Text(
                bodyText ?? s.confirmThisAction + "?",
                style: OrchidText.body2.black,
              ),
          actions: <Widget>[
            // CANCEL
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                side: BorderSide(
                  color: OrchidColors.dark_background,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  cancelText ?? s.cancelButtonTitle,
                  style:
                      dark ? OrchidText.button.white : OrchidText.button.black,
                ),
              ),
              onPressed: () {
                if (cancelAction != null) {
                  cancelAction();
                }
                Navigator.of(context).pop(false);
              },
            ),
            // ACTION
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                side: BorderSide(
                  color:
                      dark ? OrchidColors.white : OrchidColors.dark_background,
                  width: 2,
                ),
                backgroundColor: OrchidColors.dark_background,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  actionText ?? S.of(context)!.ok,
                  style: OrchidText.button,
                ),
              ),
              onPressed: () {
                if (commitAction != null) {
                  commitAction();
                }
                Navigator.of(context).pop(true);
                // return true;
              },
            ),
          ],
        );
      },
    );
  }
}
