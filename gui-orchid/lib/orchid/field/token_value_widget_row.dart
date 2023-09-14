import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/pricing/usd.dart';

// Display token value (child widget) and symbol on a row with usd price in a row below
class TokenValueWidgetRow extends StatelessWidget {
  final BuildContext context;
  final Widget child;
  final TokenType? tokenType;
  final Token? value;
  final USD? price;
  final bool enabled;

  // Used for the token symbol
  final Color? textColor;

  bool get disabled => !enabled;

  const TokenValueWidgetRow({
    Key? key,
    required this.context,
    required this.child,
    this.tokenType,
    this.value,
    required this.price,
    this.enabled = true,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usdValueText = USD.formatUSDValue(
        context: context, price: price, tokenAmount: value, showSuffix: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Token value
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            child,
            Text((tokenType ?? Tokens.TOK).symbol)
                .extra_large
                .withColor(textColor)
                .inactiveIf(disabled),
          ],
        ).top(8).height(26),
        // USD value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(usdValueText)
                .caption
                .medium
                .new_purple_bright
                .inactiveIf(disabled),
            Text('USD').caption.medium.new_purple_bright.inactiveIf(disabled),
          ],
        ).height(24),
      ],
    );
  }
}
