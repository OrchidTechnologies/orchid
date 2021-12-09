import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/on_off.dart';

class Release {
  /// This is a manually incremented release notes version.
  /// The user will see combined release notes for all versions after any previously
  /// viewed version number.
  static ReleaseVersion current = ReleaseVersion(2);

  // Build a generic "what's new" title string showing the current version number
  static Future<String> whatsNewTitle(BuildContext context) async {
    // e.g. "0.9.24 (48.299352.835478)";
    var version = await OrchidAPI().versionString();
    if (version.contains(' ')) {
      version = version.split(' ')[0];
    }
    return S.of(context).whatsNewInOrchid + ' $version?';
  }

  static Future<Widget> messagesSince(
      BuildContext context, ReleaseVersion lastVersion) async {
    // Concatenate messages starting at the version after last viewed
    List<Widget> children = [];
    for (var i = lastVersion.version + 1; i <= current.version; i++) {
      children.add(await message(context, i));
      if (i < current.version) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(
            color: Colors.white.withOpacity(0.3),
          ),
        ));
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children),
      ),
    );
  }

  static Future<Widget> message(BuildContext context, int version) async {
    switch (version) {
      case 1:
        return version1(context);
        break;
      case 2:
        return version2(context);
        break;
      default:
        return Container();
    }
  }

  // Build the release message for version 2
  static Future<Widget> version2(BuildContext context) async {
    final dollarPac = await OrchidPurchaseAPI.getDollarPAC();
    final s = S.of(context);
    final headingStyle = OrchidText.subtitle.purpleBright;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.newCircuitBuilder, style: headingStyle),
          pady(8),
          Text(
            s.youCanNowPayForAMultihopOrchidCircuitWith,
            style: OrchidText.body1,
          ),
          pady(8),
          Text(
            s.manageYourConnectionFromTheCircuitBuilderInsteadOfThe,
            style: OrchidText.body1,
          ),
          pady(16),
          Text(s.quickStartFor1(dollarPac.localDisplayPrice), style: headingStyle),
          pady(8),
          Text(
            s.weAddedAMethodToPurchaseAnOrchidAccountAnd,
            style: OrchidText.body1,
          ),
        ]);
  }

  // Build the release message for version 1
  static Widget version1(BuildContext context) {
    var headingStyle = OrchidText.subtitle.purpleBright;
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
            style: OrchidText.body1,
          ),
          pady(16),
          Text(s.xdaiAccountsForPastPurchases, style: headingStyle),
          pady(8),
          Text(
            s.forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave,
            style: OrchidText.body1,
          ),
          pady(16),
        ],
        Text(s.newInterface, style: headingStyle),
        pady(8),
        Text(
          s.accountsAreNowOrganizedUnderTheOrchidAddressTheyAre +
              " " +
              s.seeYourActiveAccountBalanceAndBandwidthCostOnThe,
          style: OrchidText.body1,
        ),
      ],
    );
  }
}
