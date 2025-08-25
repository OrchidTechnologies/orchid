import 'dart:async';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/historical_gas_prices.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_market_v1.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/util/poller.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:styled_text/styled_text.dart';

class OrchidWidgetHome extends StatefulWidget {
  const OrchidWidgetHome({Key? key}) : super(key: key);

  @override
  _OrchidWidgetHomeState createState() => _OrchidWidgetHomeState();
}

class _OrchidWidgetHomeState extends State<OrchidWidgetHome> {
  List<_ChainModel> _chains = [];
  var _disposal = [];
  bool _showPricesUSD = false;
  bool _showConfig = false;

  // Tracks expanded chains by their stable chainId (not by list index) to survive resorting
  final Set<int> _expandedChainIds = {};

  @override
  void initState() {
    super.initState();
    Poller.call(_update).nowAndEvery(seconds: 60).dispose(_disposal);
  }

  // map of chain IDs to historical gas prices
  static final Map<int, List<GasPrice>> _historicalGasPrices = {};

  void _initHistoricalGasPrices(Chain chain) async {
    if (_historicalGasPrices[chain.chainId] != null) {
      log('Historical gas prices already initialized for ${chain.name}');
      return;
    }
    try {
      final gasPrices =
          await HistoricalGasPrices.historicalGasPrices(chain: chain, days: 30);
      if (gasPrices != null) {
        setState(() {
          _historicalGasPrices[chain.chainId] =
              gasPrices.whereType<GasPrice>().toList();
        });
        log('Fetched historical gas prices for ${chain.name}: ${_historicalGasPrices[chain.chainId]?.length} entries');
      } else {
        log('No historical gas prices available for ${chain.name}');
      }
    } catch (err) {
      log('Error fetching historical gas prices for ${chain.name}: $err');
    }
  }

  void _update() async {
    _chains = Chains.map.values
        .where((e) => ![Chains.GanacheTest].contains(e))
        .map((e) => _ChainModel(
              chain: e,
              fundsToken: e.nativeCurrency,
              version: 1,
            ))
        .toList();

    await Future.wait(_chains.map((_ChainModel e) async {
      try {
        await e.init();
      } catch (err) {
        log('Error in init chain model for ${e.chain.name}: $err');
      }
      setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = OrchidText.caption.tappable;
    final descriptiveText = StyledText(
      textAlign: TextAlign.center,
      style: OrchidText.caption.copyWith(height: 1.3),
      text: s.estimatedCostToCreateAnOrchidAccountWith(
              '${(_ChainModel.targetEfficiency * 100.0).toInt()}%',
              _ChainModel.targetTickets) +
          '\n' +
          s.linklearnMoreAboutOrchidAccountslink,
      tags: {
        'link': linkStyle.link(OrchidUrls.partsOfOrchidAccount),
      },
    );

    var chains = List<_ChainModel>.from(_chains);
    chains.sort((_ChainModel a, _ChainModel b) {
      return ((a.totalCostToCreateAccount?.value ?? 1e6)
          .compareTo((b.totalCostToCreateAccount?.value ?? 1e6)));
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _totalWidth,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  _buildHeaderRow(_columnTitles()).bottom(2),
                  Divider(color: Colors.white.withOpacity(1.0)),
                ] +
                chains
                    .mapIndexed((e, i) =>
                        _buildChainRow(e, i, last: i == chains.length - 1))
                    .toList() +
                [
                  // pady(24),
                  AnimatedSize(
                    alignment: Alignment.topCenter,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.5)),
                                onPressed: () =>
                                    setState(() => _showConfig = !_showConfig),
                              ).bottom(4).right(8),
                              Text('*').subtitle.bottom(16).right(8),
                              descriptiveText,
                            ],
                          ),
                        ),
                        if (_showConfig)
                          Container(
                            // height: 200.0,
                            // color: Colors.white12,
                            alignment: Alignment.topCenter,
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  'Target efficiency: ${(_ChainModel.targetEfficiency * 100).toStringAsFixed(0)}%',
                                ).body2,
                                FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Slider(
                                    min: 0.0,
                                    max: 0.99,
                                    divisions: 100,
                                    value: _ChainModel.targetEfficiency,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white38,
                                    onChanged: (val) => setState(
                                      () => _ChainModel.targetEfficiency = val,
                                    ),
                                    onChangeEnd: (val) => _update(),
                                  ),
                                ),
                                Text(
                                  'Number of tickets: ${_ChainModel.targetTickets}',
                                ).body2,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: _ChainModel.targetTickets > 1
                                          ? () => setState(() {
                                                _ChainModel.targetTickets--;
                                                _update();
                                              })
                                          : null,
                                    ),
                                    Text('${_ChainModel.targetTickets}').body2,
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () => setState(() {
                                        _ChainModel.targetTickets++;
                                        _update();
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).top(16.0),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }

  List<String> _columnTitles() {
    return [
      s.chain,
      s.token,
      s.minDeposit,
      s.minBalance,
      s.fundFee,
      s.withdrawFee,
      '', // expand icon column
    ];
  }

  Widget _buildDetailRow(String title, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140.0,
            child: Text(title).body2,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
        ],
      ),
    );
  }

  final _columnSizes = [215, 80, 135, 135, 110, 140, 48];

  double get _totalWidth {
    return _columnSizes.reduce((value, element) => value + element).toDouble() +
        80.0;
  }

  Widget column(int i, {required Widget child}) {
    return SizedBox(
      width: _columnSizes[i].toDouble(),
      child: child,
    );
  }

  Widget _buildHeaderRow(List<String> titles) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showPricesUSD = !_showPricesUSD;
                });
              },
              child: Text(_showPricesUSD ? s.tokenValues : s.usdPrices)
                  .caption
                  .tappable
                  .right(32),
            ),
          ],
        ),
        pady(16),
        Row(
          children: titles
              .mapIndexed((e, i) =>
                  column(i, child: Text(e).title.copyWith(textScaleFactor: 1)))
              .toList(),
        ),
      ],
    );
  }

  // Chain | Token | Min Deposit | Min Balance | Fund fee | Withdraw fee
  Widget _buildChainRow(_ChainModel model, int rowIndex, {bool last = false}) {
    final stats = model.stats;

    final chainCell = Row(
      children: [
        SizedBox(height: 20, width: 20, child: model.chain.icon),
        padx(16),
        Text(model.chain.name).body2,
      ],
    );

    final tokenCell = Text(model.fundsToken.symbol).body2;

    Widget valueCell(
      Token? token,
      USD? tokenUSDPrice, {
      minPrecision = 4,
      maxPrecision = 4,
      bool selectable = false,
    }) {
      if (token == null || tokenUSDPrice == null) {
        return Container();
      }
      if (_showPricesUSD) {
        final text = (tokenUSDPrice * token.doubleValue).formatCurrency(
          locale: context.locale,
          minPrecision: minPrecision,
          maxPrecision: maxPrecision,
          showPrecisionIndicator: true,
        );
        return selectable
            ? SelectableText(text, style: OrchidText.body2)
            : Text(text, style: OrchidText.body2);
      } else {
        final text = token.toFixedLocalized(
            locale: context.locale,
            minPrecision: minPrecision,
            maxPrecision: maxPrecision,
            showPrecisionIndicator: true);
        return selectable
            ? SelectableText(text, style: OrchidText.body2)
            : Text(text, style: OrchidText.body2);
      }
    }

    final depositCell = valueCell(stats?.createDeposit, model.fundsTokenPrice);
    final balanceCell = valueCell(stats?.createBalance, model.fundsTokenPrice);
    final fundCell = valueCell(stats?.createGas, model.gasTokenPrice);
    final withdrawCell = valueCell(stats?.withdrawGas, model.gasTokenPrice);

    final depositCellFull = valueCell(
        stats?.createDeposit, model.fundsTokenPrice,
        minPrecision: 2, maxPrecision: 18, selectable: true);
    final balanceCellFull = valueCell(
        stats?.createBalance, model.fundsTokenPrice,
        minPrecision: 2, maxPrecision: 18, selectable: true);
    final fundCellFull = valueCell(stats?.createGas, model.gasTokenPrice,
        minPrecision: 2, maxPrecision: 18, selectable: true);
    final withdrawCellFull = valueCell(stats?.withdrawGas, model.gasTokenPrice,
        minPrecision: 2, maxPrecision: 18, selectable: true);

    // Stats column cells: efficiency, tickets, gas price (full precision/selectable)
    final efficiencyCell = stats != null
        ? Text(
            '${(stats.efficiency * 100).toStringAsFixed(2)}%',
            style: OrchidText.body2,
          )
        : Container();
    final ticketsCell = stats != null
        ? Text('${stats.tickets}', style: OrchidText.body2)
        : Container();
    final gasPriceCell = valueCell(stats?.gasPrice, model.gasTokenPrice,
        minPrecision: 2, maxPrecision: 18, selectable: true);

    // Chain info cells (excluding name & token)
    final chainIdCell = Text('${model.chain.chainId}', style: OrchidText.body2);

    final rpcUrlCell = Text(model.chain.providerUrl.truncate(32))
        .linkStyle
        .link(url: model.chain.providerUrl);

    final blocktimeCell =
        Text('${model.chain.blocktime}s', style: OrchidText.body2);
    final confirmationsCell =
        Text('${model.chain.requiredConfirmations}', style: OrchidText.body2);
    final logsCell =
        Text(model.chain.supportsLogs ? 'Yes' : 'No', style: OrchidText.body2);
    final eip1559Cell =
        Text(model.chain.eip1559 ? 'Yes' : 'No', style: OrchidText.body2);
    final feesCell = Text(
        model.chain.hasNonstandardTransactionFees ? 'Yes' : 'No',
        style: OrchidText.body2);

    final explorerCell = model.chain.explorerUrl != null
        ? Text(model.chain.explorerUrl!.truncate(32))
            .linkStyle
            .link(url: model.chain.explorerUrl!)
        : Container();

    final expanded = _expandedChainIds.contains(model.chain.chainId);
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          // Tooltip(
          //   message: model.tooltipText(context),
          //   textStyle: OrchidText.body2.copyWith(height: 1.2),
          //   child:
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              if (expanded) {
                _expandedChainIds.remove(model.chain.chainId);
              } else {
                _expandedChainIds.add(model.chain.chainId);
                _initHistoricalGasPrices(model.chain);
              }
            }),
            child: Row(
              children: [
                column(0, child: chainCell),
                column(1, child: expanded ? Container() : tokenCell),
                column(2, child: expanded ? Container() : depositCell),
                column(3, child: expanded ? Container() : balanceCell),
                column(4, child: expanded ? Container() : fundCell),
                column(5, child: expanded ? Container() : withdrawCell),
                column(
                  6,
                  child: IconButton(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    icon:
                        Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() {
                      if (expanded)
                        _expandedChainIds.remove(model.chain.chainId);
                      else
                        _expandedChainIds.add(model.chain.chainId);
                    }),
                  ),
                ).height(24),
              ],
            ),
          ),
          // ),
          if (expanded)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _buildDetailRow(s.efficiency, efficiencyCell),
                        // _buildDetailRow(s.tickets, ticketsCell),
                        _buildDetailRow(s.minDeposit+' *', depositCellFull),
                        _buildDetailRow(s.minBalance+' *', balanceCellFull),
                        _buildDetailRow(s.fundFee, fundCellFull),
                        _buildDetailRow(s.withdrawFee, withdrawCellFull),
                        if (model.chain.eip1559)
                          _buildGasPriceChart(model.chain).top(0.0),
                      ],
                    ),
                  ),
                  SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(s.gasPrice, gasPriceCell),
                        // Chain info (excludes name & token)
                        _buildDetailRow('Chain ID', chainIdCell),
                        _buildDetailRow(s.rpcUrl, rpcUrlCell),
                        _buildDetailRow('Block time', blocktimeCell),
                        _buildDetailRow('Confirmations', confirmationsCell),
                        _buildDetailRow('Logs', logsCell),
                        _buildDetailRow('EIP-1559', eip1559Cell),
                        _buildDetailRow('Nonstandard fees', feesCell),
                        _buildDetailRow(s.blockExplorer, explorerCell),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // if (!last)
          Divider(color: Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildGasPriceChart(Chain chain) {
    final gasPrices = _historicalGasPrices[chain.chainId];
    if (gasPrices == null || gasPrices.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OrchidCircularProgressIndicator.smallIndeterminate(size: 16),
          Text('Sampling gas prices for ${chain.name}...').body2.left(12),
        ],
      ).height(50).top(16);
    }

    // ----
    // Extract the gas prices and dates, map to gwei
    // ----
    final int weiPerGwei = 1e9.toInt();

    // Extract the gas prices and dates
    final prices = gasPrices.map((gp) => gp.price.toDouble()).toList();

    // Min/Max in wei
    final double minWei = prices.reduce((a, b) => a < b ? a : b);
    final double maxWei = prices.reduce((a, b) => a > b ? a : b);

    // Choose the display unit: switch to gwei if any value is ≥ 1 gwei
    final bool useGwei = maxWei >= weiPerGwei / 1000;
    print(
        "XXX: chain = $chain: useGwei = $useGwei, minWei = $minWei, maxWei = $maxWei");
    String format(double wei) => useGwei
        ? (wei / weiPerGwei).toStringAsFixed(2)
        : wei.toStringAsFixed(2);
    final unit = useGwei ? 'gwei' : 'wei';

    String text = "Sampled 30 day gas prices: ";
    String minMax = "min: ${format(minWei)} $unit, "
        "max: ${format(maxWei)} $unit";
    String caption = "$text $minMax";
    // ----

    return Column(
      children: [
        // Text('Historical Gas Prices for ${chain.name}').body2,
        SizedBox(
          height: 50,
          child: Sparkline(data: prices),
        ),
        Text(caption).body2.withStyle(TextStyle(fontSize: 12)).white.top(12),
      ],
    ).top(8);
  }

  @override
  void dispose() {
    _disposal.dispose();
    super.dispose();
  }
}

class _ChainModel {
  static double targetEfficiency = 0.9;
  static int targetTickets = 4;

  final Chain chain;
  final TokenType fundsToken;

  /// The contract version for price calculations
  final int version;

  PotStats? stats;
  USD? totalCostToCreateAccount;
  USD? fundsTokenPrice;
  USD? gasTokenPrice;

  _ChainModel({
    required this.chain,
    required this.fundsToken,
    this.version = 1,
  });

  String tooltipText(BuildContext context) {
    return '${chain.name} ${fundsToken.symbol}, ' +
        context.s.total +
        ': ${totalCostToCreateAccount?.formatCurrency(
              locale: context.locale,
              minPrecision: 2,
              maxPrecision: 18,
            ) ?? ''}';
  }

  Future<void> init() async {
    if (version == 1) {
      stats = await MarketConditionsV1.getPotStats(
          chain: chain, efficiency: targetEfficiency, tickets: targetTickets);

      fundsTokenPrice = USD(await OrchidPricing().usdPrice(fundsToken));
      gasTokenPrice = USD(await OrchidPricing().usdPrice(chain.nativeCurrency));
      totalCostToCreateAccount = await OrchidPricing()
              .tokenToUSD(stats!.createBalance + stats!.createDeposit) +
          await OrchidPricing().tokenToUSD(stats!.createGas);
    }
  }
}
