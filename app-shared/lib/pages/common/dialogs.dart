import 'package:flutter/material.dart';

class Dialogs {
  static final String syncRequiredTitle = "Sync required";
  static final String syncRequiredText =
      "Orchid needs to sync with the server directory, but you have elected to only sync when connected to WiFi. You may continue using Orchid once you have passed the minimum sync threshold.\n\nYour syncing options can always be changed in settings.";

  // TODO: Move to relevant screen
  static void showSyncRequiredDialog(@required BuildContext context) {
    showAppDialog(
        context: context,
        title: syncRequiredTitle,
        body: syncRequiredText,
        linkSettings: true);
  }

  // TODO: Move to relevant screen
  static void showWalletLinkedDialog(@required BuildContext context) {
    showAppDialog(
        context: context,
        title: "Wallet linked!",
        body:
            "Your linked wallet will be used to pay for bandwidth on Orchid.");
  }

  // TODO: Move to relevant screen
  static void showWalletLinkFailedDialog(@required BuildContext context) {
    showAppDialog(
        context: context,
        title: "Whoops!",
        body:
            "Orchid was unable to connect to an Ethereum wallet using the private key you provided.\n\nPlease check and make sure the information you entered was correct.");
  }

  /// Show a styled Orchid app dialog with title, body, OK button, and optional link to settings.
  static void showAppDialog({
    @required BuildContext context,
    @required String title,
    @required String body,
    bool linkSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          title: Text(title,
              style: const TextStyle(
                  color: const Color(0xff3a3149),
                  fontWeight: FontWeight.w400,
                  fontFamily: "Roboto",
                  fontStyle: FontStyle.normal,
                  fontSize: 20.0)),
          content: Text(body,
              style: const TextStyle(
                  color: const Color(0xff504960),
                  fontWeight: FontWeight.w400,
                  fontFamily: "Roboto",
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0)),
          actions: <Widget>[
            linkSettings
                ? new FlatButton(
                    child: new Text(
                      "SETTINGS",
                      style: const TextStyle(
                          letterSpacing: 1.25,
                          color: const Color(0xff5f45ba),
                          fontWeight: FontWeight.w400,
                          fontFamily: "Roboto",
                          fontStyle: FontStyle.normal,
                          fontSize: 14.0),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/settings');
                    },
                  )
                : null,
            new FlatButton(
              child: new Text(
                "OK",
                style: const TextStyle(
                    letterSpacing: 1.25,
                    color: const Color(0xff5f45ba),
                    fontWeight: FontWeight.w400,
                    fontFamily: "Roboto",
                    fontStyle: FontStyle.normal,
                    fontSize: 14.0),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
