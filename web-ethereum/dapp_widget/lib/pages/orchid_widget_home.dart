import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_market_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/collections.dart';
import 'package:orchid/util/units.dart';
import 'package:styled_text/styled_text.dart';

class OrchidWidgetHome extends StatefulWidget {
  const OrchidWidgetHome({Key key}) : super(key: key);

  @override
  _OrchidWidgetHomeState createState() => _OrchidWidgetHomeState();
}

class _OrchidWidgetHomeState extends State<OrchidWidgetHome> {
  List<_ChainModel> _chains = [];
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 15), (timer) async {
      _update();
    });
    _update();
  }

  void _update() async {
    _chains = Chains.map.values
        .where((e) => ![Chains.GanacheTest].contains(e))
        .map((e) => _ChainModel(
              chain: e,
              token: e == Chains.Ethereum ? TokenTypes.OXT : e.nativeCurrency,
              version: e == Chains.Ethereum ? 0 : 1,
            ))
        .toList();

    await Future.wait(_chains.map((_ChainModel e) async {
      try {
        await e.init();
      } catch (err) {
        log("Error in init chain model for ${e.chain.name}: $err");
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
      text: "Estimated cost to create an Orchid Account with "
          "an efficiency of ${_ChainModel.targetEfficiency * 100.0}% and "
          "${_ChainModel.targetTickets} tickets of value.\n<link>Learn more about Orchid Accounts</link>.",
      tags: {
        'link': linkStyle.link(OrchidUrls.partsOfOrchidAccount),
      },
    );

    var chains = List<_ChainModel>.from(_chains);
    chains.sort((_ChainModel a, _ChainModel b) {
      return ((a.costToCreateAccountUSD ?? 1e6)
          .compareTo((b.costToCreateAccountUSD ?? 1e6)));
    });

    return SizedBox(
      width: 700,
      height: 500,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
                _buildHeaderRow([
                  "Chain",
                  "Token",
                  "Price",
                  "Create Account Cost",
                ]).bottom(2),
                Divider(color: Colors.white.withOpacity(1.0)),
              ] +
              chains
                  .mapIndexed((e, i) =>
                      _buildChainRow(e, last: i == chains.length - 1))
                  .toList() +
              [pady(24), text],
        ),
      ),
    );
  }

  Widget column(int i, {Widget child}) {
    final sizes = [215, 80, 130, 220];
    return SizedBox(
      width: sizes[i].toDouble(),
      child: child,
    );
  }

  Widget _buildHeaderRow(List<String> titles) {
    return Row(
      children:
          titles.mapIndexed((e, i) => column(i, child: Text(e).title)).toList(),
    );
  }

  Widget _buildChainRow(_ChainModel model, {bool last = false}) {
    return Tooltip(
      message: model.tooltipText,
      textStyle: OrchidText.body2.copyWith(height: 1.2),
      child: Column(
        children: [
          Row(
            children: [
              column(
                0,
                child: Row(
                  children: [
                    SizedBox(height: 20, width: 20, child: model.chain.icon),
                    padx(16),
                    Text(model.chain.name).body2,
                  ],
                ),
              ),
              column(
                1,
                child: Text(model.token.symbol).body2,
              ),
              column(
                2,
                child: model.tokenPriceUSD != null
                    ? Text('\$' + formatCurrency(model.tokenPriceUSD, digits: 2))
                        .body2
                    : Container(),
              ),
              column(
                3,
                child: model.costToCreateAccountUSD != null
                    ? Text('\$' +
                            formatCurrency(model.costToCreateAccountUSD,
                                digits: 2))
                        .body2
                    : Container(),
              ),
            ],
          ),
          if (!last) Divider(color: Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class _ChainModel {
  static final targetEfficiency = 0.9;
  static final targetTickets = 2;

  final Chain chain;
  final TokenType token;

  /// The contract version for price calculations
  final int version;

  double tokenPriceUSD;
  double costToCreateAccountUSD;

  _ChainModel({
    @required this.chain,
    @required this.token,
    this.version = 1,
  });

  String get tooltipText {
    return chain.name;
  }

  Future<void> init() async {
    tokenPriceUSD = await OrchidPricing().usdPrice(token);
    if (version == 1) {
      costToCreateAccountUSD = (await MarketConditionsV1.getCostToCreateAccount(
                  chain: chain,
                  efficiency: targetEfficiency,
                  tickets: targetTickets))
              .floatValue *
          tokenPriceUSD;
      // log("XXX: chain = $chain, tokenPrice = $tokenPriceUSD, cost = $costToCreateAccountUSD");
    }
    if (version == 0) {
      costToCreateAccountUSD = (await MarketConditionsV0.getCostToCreateAccount(
                  efficiency: targetEfficiency, tickets: targetTickets))
              .floatValue *
          tokenPriceUSD;
      // log("XXX: V0! tokenPrice = $tokenPriceUSD, cost = $costToCreateAccountUSD");
    }
  }
}
