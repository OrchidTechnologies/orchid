import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

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
    // var bodyStyle = AppText.dialogBody.copyWith(fontSize: 14, color: Colors.black);
    var bodyStyle = OrchidText.body1;

    // var headingStyle = bodyStyle.copyWith(fontWeight: FontWeight.bold);
    var headingStyle = OrchidText.subtitle.copyWith(color: OrchidColors.purple_bright);

    var s = S.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: Column(
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
      ),
    );
  }
}
