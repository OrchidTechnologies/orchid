import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/util/polling_builder.dart';
import 'package:orchid/api/pricing/usd.dart';

// TODO: expand to multi-token, selectable currency
class TokenPriceBuilder extends StatelessWidget {
  final TokenType tokenType;
  final int seconds;
  final Widget Function(USD? price) builder;

  const TokenPriceBuilder({
    Key? key,
    required this.tokenType,
    this.seconds = 30,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PollingBuilder.interval(
      key: Key(tokenType.toString()),
      seconds: seconds,
      poll: () async {
        return USD(await OrchidPricing().usdPrice(tokenType));
      },

      // builder: builder,
      // must cast to dynamic here
      builder: (dynamic arg) {
        return builder(arg);
      },

    );
  }
}
