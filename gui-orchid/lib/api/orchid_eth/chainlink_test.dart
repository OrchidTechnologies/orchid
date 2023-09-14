import 'dart:math';
import 'chainlink.dart';
import 'chains.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/series_binary_search.dart';

class ChainlinkTest {

  static void testWalkBack(Chain chain, String contractAddress) async {
    log("test chainlink contract...");
    var decimals = await Chainlink.decimals(chain: chain, contract: contractAddress);
    var _latestRoundData =
    await Chainlink.latestRoundData(chain: chain, contract: contractAddress);
    log("latestRoundData = $_latestRoundData");

    final latestProxyRoundId = _latestRoundData.roundId;
    final latestPhase = (latestProxyRoundId >> 64).toInt();
    final latestRound =
    (latestProxyRoundId & BigInt.from(pow(2, 16) - 1)).toInt();
    log("latestProxyRoundId: $latestProxyRoundId, latestPhaseId: $latestPhase, latestRoundId: $latestRound");

    // loop until we reach target date or run out of round ids in this contract version
    int days = 300;
    var targetDate = DateTime.now().subtract(Duration(days: days));
    var count = 0;
    for (var round = latestRound; round >= 0; round -= 1) {
      count += 1;
      var roundData = await Chainlink.getRoundDataFor(
        decimals: decimals,
          chain: chain,
          contract: contractAddress,
          phase: latestPhase,
          round: round);
      var date = roundData.date;

      var price = roundData.answer.toInt() / pow(10, decimals);
      log("date = $date, price = $price");
      if (date.isBefore(targetDate)) {
        break;
      }
    }
    log("count = $count, interval = ${count / days} per day");
  }

  static void testSearchBack(Chain chain, String contractAddress) async {
    int totalLookups = 0;

    var latestRoundData = await Chainlink.latestRoundData(chain: chain, contract: contractAddress);
    int decimals = latestRoundData.decimals;
    final latestProxyRoundId = latestRoundData.roundId;

    final latestPhase = (latestProxyRoundId >> 64).toInt();
    final latestRound =
    (latestProxyRoundId & BigInt.from(pow(2, 16) - 1)).toInt();

    final search = SeriesBinarySearch<DateTime>(
      minIndex: 0,
      maxIndex: latestRound,
      startIndex: latestRound,
      valueForIndex: (i) async {
        totalLookups += 1;
        print("value for index: $i");
        final roundData = await Chainlink.getRoundDataFor(
          decimals: decimals,
          chain: chain,
          contract: contractAddress,
          phase: latestPhase,
          round: i,
        );
        return roundData.date;
      },
      seriesExpectedInterval: 48,
    );

    int days = 30;
    int missing = 0;
    for (var i = 0; i < days; i++) {
      var range = DateTimeComparable(
        date: DateTime.now().subtract(Duration(days: i)),
        within: Duration(hours: 12),
      );
      var found = await search.findNext(range);
      if (found != null) {
        print("found = $found");
      } else {
        missing += 1;
        print("MISSING!");
      }
    }
    print("totalLooksups = $totalLookups, total missing = $missing");
  }

  static void runTests() async {
    var prices;
    // prices = await Chainlink.historicalTokenPrice(chain: Chains.Ethereum, days: 30);
    // prices = await Chainlink.historicalTokenPrice(chain: Chains.Avalanche, days: 30);
    // prices = await Chainlink.historicalTokenPrice(chain: Chains.BinanceSmartChain, days: 30);
    // prices = await Chainlink.historicalTokenPrice(chain: Chains.Polygon, days: 30);
    // prices = await Chainlink.historicalTokenPrice(chain: Chains.Gnosis, days: 30);
    // prices = await Chainlink.historicalTokenPrice(chain: Chains.RSK, days: 30);
    // testWalkBack(Chains.Ethereum, ChainlinkContract.eth_usd);
    // testWalkBack(ChainlinkContractWeb3.avax_usd);
    // testWalkBack(ChainlinkContractWeb3.bnb_usd);
    // testWalkBack(ChainlinkContractWeb3.matic_usd);

    // testSearchBack(Chains.Ethereum, ChainlinkContract.eth_usd);
    // testSearchBack(Chains.Ethereum, ChainlinkContract.avax_usd);
    // testSearchBack(Chains.Ethereum, ChainlinkContract.bnb_usd);
    // testSearchBack(Chains.Ethereum, ChainlinkContract.matic_usd);

    // The ftm-usd oracle on the Fantom chain doesn't seem to have any data
    // after 01/25/2022.
    // There seems to be an active ftm-usd oracle on Optimism, however we are severely
    // rate limited on the rpc url.
    // final ftm_usd_optimism = '0xc19d58652d6BfC6Db6FB3691eDA6Aa7f3379E4E9';
    // testWalkBack(Chains.Optimism, ftm_usd_optimism);
    // testSearchBack(Chains.Optimism, ftm_usd_optimism);
    // The ftm-usd contract on polygon seems active
    // final ftm_usd_polygon = '0x58326c0f831b2dbf7234a4204f28bba79aa06d5f';
    // testWalkBack(Chains.Polygon, ftm_usd_polygon);
    // testSearchBack(Chains.Polygon, ftm_usd_polygon);
  }
}