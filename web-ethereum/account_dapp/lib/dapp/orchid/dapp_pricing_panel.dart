import 'dart:math';
import 'package:orchid/api/orchid_eth/chainlink.dart';
import 'package:orchid/api/orchid_eth/historical_gas_prices.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/chains.dart';

// TODO: Just a placeholder... Needs a proper design.
class HistoricalPricingPanel extends StatefulWidget {
  final Chain chain;

  const HistoricalPricingPanel({
    Key? key,
    required this.chain,
  }) : super(key: key);

  @override
  State<HistoricalPricingPanel> createState() => _HistoricalPricingPanelState();
}

class _HistoricalPricingPanelState extends State<HistoricalPricingPanel> {
  /// token price history for current chain
  late List<TokenPrice?>? _historicalTokenPrice;

  /// gas price history for current chain
  late List<GasPrice?>? _historicalGasPrice;

  Chain get chain => widget.chain;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    await _getHistoricalPricing();
  }

  Future<void> _getHistoricalPricing() async {
    final days = 7;
    _historicalTokenPrice =
        await Chainlink.historicalTokenPrice(chain: chain, days: days);
    setState(() {});
    _historicalGasPrice =
        await HistoricalGasPrices.historicalGasPrices(chain: chain, days: days);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _buildHistoricalPricing();
  }

  Widget _buildHistoricalPricing() {
    // at least one set
    if (_historicalTokenPrice == null && _historicalGasPrice == null) {
      return Container();
    }
    // should have the same length
    if (_historicalTokenPrice != null &&
        _historicalGasPrice != null &&
        (_historicalTokenPrice!.length != _historicalGasPrice!.length)) {
      return Container();
    }
    int len = max((_historicalTokenPrice ?? []).length,
        (_historicalGasPrice ?? []).length);
    List<Widget> panels = [];
    for (var i = 0; i < len; i++) {
      panels.add(_buildHistoricalPricePanel(
        _historicalTokenPrice != null ? _historicalTokenPrice![i] : null,
        _historicalGasPrice != null ? _historicalGasPrice![i] : null,
      ));
    }

    panels.insert(0, _buildHistoricalPriceLabelPanel(chain.nativeCurrency));

    return SizedBox(
      height: 100,
      child: RoundedRect(
        backgroundColor: OrchidColors.dark_background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: panels,
        ).pady(8),
      ),
    );
  }

  Widget _buildHistoricalPriceLabelPanel(TokenType? tokenType) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Date").body1.white,
        if (tokenType != null)
          SizedBox(height: 24, child: tokenType.icon)
        else
          SizedBox(height: 24),
        Icon(Icons.local_gas_station, color: Colors.white),
      ],
    );
  }

  Widget _buildHistoricalPricePanel(TokenPrice? token, GasPrice? gas) {
    final date = token != null ? token.date : (gas != null ? gas.date : null);
    final dateText = date != null ? date.toShortDateString() : '...';
    final tokenText = token != null ? token.priceUSD.toStringAsFixed(2) : '...';
    final gasText =
        gas != null ? (gas.price / BigInt.from(1e9)).toStringAsFixed(2) : '...';
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(dateText).caption,
        Text(tokenText).caption,
        Text(gasText).caption,
      ],
    );
  }
}
