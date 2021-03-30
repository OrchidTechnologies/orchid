import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/generated/l10n.dart';
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
    return S.of(context).whatsNewInOrchid + ' $version?';
  }

  // Build a release message
  static Widget message(BuildContext context) {
    var bodyStyle =
        AppText.dialogBody.copyWith(fontSize: 14, color: Colors.black);
    var headingStyle = bodyStyle.copyWith(fontWeight: FontWeight.bold);

    var s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (OrchidPlatform.isApple) ...[
          Text(s.orchidIsOnXdai, style: headingStyle),
          pady(8),
          Text(
            s.youCanNowPurchaseOrchidCreditsOnXdaiStartUsing,
            style: bodyStyle,
          ),
          pady(16),
          Text(s.xdaiAccountsForPastPurchases, style: headingStyle),
          pady(8),
          Text(
            s.forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave,
            style: bodyStyle,
          ),
          pady(16),
        ],
        Text(s.newInterface, style: headingStyle),
        pady(8),
        Text(
          s.accountsAreNowOrganizedUnderTheOrchidAddressTheyAre +" " +
          s.seeYourActiveAccountBalanceAndBandwidthCostOnThe,
          style: bodyStyle,
        ),
      ],
    );
  }
}
