import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_market_v1.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/collections.dart';
import 'package:orchid/util/dispose.dart';
import 'package:orchid/util/poller.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:styled_text/styled_text.dart';
import 'package:orchid/util/localization.dart';

class OrchidWidgetHome extends StatefulWidget {
  const OrchidWidgetHome({Key? key}) : super(key: key);

  @override
  _OrchidWidgetHomeState createState() => _OrchidWidgetHomeState();
}

class _OrchidWidgetHomeState extends State<OrchidWidgetHome> {
  List<_ChainModel> _chains = [];
  var _disposal = [];
  bool _showPricesUSD = false;

  @override
  void initState() {
    super.initState();
    Poller.call(_update).nowAndEvery(seconds: 15).dispose(_disposal);
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
    final text = StyledText(
      textAlign: TextAlign.center,
      style: OrchidText.caption,
      text: s.estimatedCostToCreateAnOrchidAccountWith(
              '${_ChainModel.targetEfficiency * 100.0}%',
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
                        _buildChainRow(e, last: i == chains.length - 1))
                    .toList() +
                [pady(24), text],
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
      s.withdrawFee
    ];
  }

  final _columnSizes = [215, 80, 135, 135, 110, 140];

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
  Widget _buildChainRow(_ChainModel model, {bool last = false}) {
    final stats = model.stats;

    final chainCell = Row(
      children: [
        SizedBox(height: 20, width: 20, child: model.chain.icon),
        padx(16),
        Text(model.chain.name).body2,
      ],
    );

    final tokenCell = Text(model.fundsToken.symbol).body2;

    Widget valueCell(Token? token, USD? tokenPrice) {
      if (token == null || tokenPrice == null) {
        return Container();
      }
      if (_showPricesUSD) {
        return Text((tokenPrice * token.floatValue)
                .formatCurrency(locale: context.locale))
            .body2;
      } else {
        return Text(token.toFixedLocalized(locale: context.locale)).body2;
      }
    }

    final depositCell = valueCell(stats?.createDeposit, model.fundsTokenPrice);
    final balanceCell = valueCell(stats?.createBalance, model.fundsTokenPrice);
    final fundCell = valueCell(stats?.createGas, model.gasTokenPrice);
    final withdrawCell = valueCell(stats?.withdrawGas, model.gasTokenPrice);

    return Tooltip(
      message: model.tooltipText(context),
      textStyle: OrchidText.body2.copyWith(height: 1.2),
      child: Column(
        children: [
          Row(
            children: [
              column(0, child: chainCell),
              column(1, child: tokenCell),
              column(2, child: depositCell),
              column(3, child: balanceCell),
              column(4, child: fundCell),
              column(5, child: withdrawCell),
              // Min Deposit | Min Balance | Fund fee | Withdraw fee
            ],
          ),
          if (!last) Divider(color: Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposal.dispose();
    super.dispose();
  }
}

class _ChainModel {
  static final targetEfficiency = 0.9;
  static final targetTickets = 4;

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
        ': ${totalCostToCreateAccount?.formatCurrency(locale: context.locale) ?? ''}';
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
    /*
    if (version == 0) {
      costToCreateAccountUSD = (await MarketConditionsV0.getPotStats(
                  efficiency: targetEfficiency, tickets: targetTickets))
              .floatValue *
          tokenPriceUSD;
      // log('XXX: V0! tokenPrice = $tokenPriceUSD, cost = $costToCreateAccountUSD');
    }
     */
  }
}
