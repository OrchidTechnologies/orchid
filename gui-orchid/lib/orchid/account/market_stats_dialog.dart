import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/pricing/orchid_pricing_v0.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/util/format_currency.dart';

class MarketStatsDialog {
  static Future<void> show({
    required BuildContext context,
    required Account account,
    required LotteryPot? lotteryPot,
    required MarketConditions? marketConditions,
  }) async {
    if (lotteryPot == null || marketConditions == null) {
      return;
    }
    final s = context.s;

    var gasPrice = await account.chain.getGasPrice();
    // bool gasPriceHigh = gasPrice.value >= 50.0;

    List<Widget> tokenPrices;
    if (account.isV0) {
      PricingV0? pricing = await OrchidPricingAPIV0().getPricing();
      if (pricing == null) {
        return;
      }
      var ethPriceText = formatCurrency(1.0 / pricing.ethPriceUSD,
          locale: context.locale, suffix: 'USD');
      var oxtPriceText = formatCurrency(1.0 / pricing.oxtPriceUSD,
          locale: context.locale, suffix: 'USD');
      tokenPrices = [
        Text(s.ethPrice + " " + ethPriceText).body2,
        Text(s.oxtPrice + " " + oxtPriceText).body2,
      ];
    } else {
      var tokenType = account.chain.nativeCurrency;
      var tokenPrice = await OrchidPricing().tokenToUsdRate(tokenType);
      var priceText =
          formatCurrency(tokenPrice, locale: context.locale, suffix: 'USD');
      tokenPrices = [
        Text(tokenType.symbol + ' ' + s.price + ': ' + priceText).body2,
      ];
    }

    // Show gas prices as "GWEI" regardless of token type.
    var gasPriceGwei = gasPrice.multiplyDouble(1e9);
    var gasPriceText = formatCurrency(gasPriceGwei.floatValue,
        locale: context.locale, suffix: 'GWEI');

    String maxFaceValueText =
        marketConditions.maxFaceValue.formatCurrency(locale: context.locale);
    String costToRedeemText =
        marketConditions.costToRedeem.formatCurrency(locale: context.locale);

    bool ticketUnderwater = marketConditions.costToRedeem.floatValue >=
        marketConditions.maxFaceValue.floatValue;

    String limitedByText = marketConditions.limitedByBalance
        ? s.yourMaxTicketValueIsCurrentlyLimitedByYourBalance +
            " ${lotteryPot.balance.formatCurrency(locale: context.locale)}.  " +
            s.considerAddingOxtToYourAccountBalance
        : s.yourMaxTicketValueIsCurrentlyLimitedByYourDeposit +
            " ${lotteryPot.deposit.formatCurrency(locale: context.locale)}.  " +
            s.considerAddingOxtToYourDepositOrMovingFundsFrom;

    String limitedByTitleText = marketConditions.limitedByBalance
        ? s.balanceTooLow
        : s.depositSizeTooSmall;

    return AppDialogs.showAppDialog(
      context: context,
      title: s.marketStats,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.prices).title,
          pady(4),
          ...tokenPrices,
          Text(
            s.gasPrice + " " + gasPriceText,
            // style: gasPriceHigh
            //     ? OrchidText.body1.copyWith(color: Colors.red)
            //     : OrchidText.body1,
            style: OrchidText.body1,
          ).body2,
          pady(16),
          Text(s.ticketValue).title,
          pady(4),

          Text(s.maxFaceValue + " " + maxFaceValueText).body2,

          Text(s.costToRedeem + " " + costToRedeemText,
              style: ticketUnderwater
                  ? OrchidText.body2.copyWith(color: Colors.red)
                  : OrchidText.body2),

          // Problem description
          if (ticketUnderwater) ...[
            pady(16),
            Text(limitedByTitleText).body1,
            pady(8),

            // Text(limitedByText, style: TextStyle(fontStyle: FontStyle.italic)),
            Text(limitedByText,
                style: OrchidText.body1.copyWith(fontStyle: FontStyle.italic)),

            pady(16),
            LinkText(s.viewTheDocsForHelpOnThisIssue,
                style: OrchidText.linkStyle,
                url:
                    'https://docs.orchid.com/en/stable/accounts/#deposit-size-too-small')
          ]
        ],
      ),
    );
  }
}
