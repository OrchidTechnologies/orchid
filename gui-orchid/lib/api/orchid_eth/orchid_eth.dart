import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_market_v1.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';

import '../orchid_budget_api.dart';
import '../orchid_crypto.dart';

class OrchidEthereum {
  final Chain chain;

  OrchidEthereum(this.chain, {int version});

  Future<LotteryPot> getLotteryPot(
      EthereumAddress funder, EthereumAddress signer) async {
    if (chain == Chains.Ethereum) {
      return OrchidEthereumV0.getLotteryPot(funder, signer);
    } else {
      return OrchidEthereumV1.getLotteryPot(
          chain: chain, funder: funder, signer: signer);
    }
  }

  Future<MarketConditions> getMarketConditions(LotteryPot pot) {
    if (chain == Chains.Ethereum) {
      return MarketConditionsV0.forPot(pot);
    } else {
      return MarketConditionsV1.forPot(pot);
    }
  }

  Future<Token> getMaxTicketValue(LotteryPot pot) {
    if (chain == Chains.Ethereum) {
      return MarketConditionsV0.getMaxTicketValueV0(pot);
    } else {
      return MarketConditionsV1.getMaxTicketValue(chain ,pot);
    }
  }

}
