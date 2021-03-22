import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/formatting.dart';

class Release {
  // Increment to display new release info
  static ReleaseVersion current = ReleaseVersion(1);

  // Build a title string
  static Future<String> title(BuildContext context) async {
    // e.g. "0.9.24 (48.299352.835478)";
    var version = await OrchidAPI().versionString();
    if (version.contains(' ')) {
      version = version.split(' ')[0];
    }
    return 'What’s new in Orchid $version?';
  }

  // Build a release message
  static Widget message(BuildContext context) {
    var bodyStyle =
        AppText.dialogBody.copyWith(fontSize: 14, color: Colors.black);
    var headingStyle = bodyStyle.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (OrchidPlatform.isApple) ...[
          Text("Orchid is on xDai!", style: headingStyle),
          pady(8),
          Text(
            "You can now purchase Orchid credits on xDai! Start using the VPN for as little as \$1.",
            style: bodyStyle,
          ),
          pady(16),
          Text("xDai accounts for past purchases", style: headingStyle),
          pady(8),
          Text(
            "For any in-app purchase made before today, xDai funds have been added to the same account key. Have the bandwidth on us!",
            style: bodyStyle,
          ),
          pady(16),
        ],
        Text("New interface", style: headingStyle),
        pady(8),
        Text(
          "Accounts are now organized under the Orchid Address they are associated with. "
          "See your active account balance and bandwidth cost on the home screen.",
          style: bodyStyle,
        ),
      ],
    );
  }
}
