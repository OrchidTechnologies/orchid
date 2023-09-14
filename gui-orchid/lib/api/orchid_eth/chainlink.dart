import 'dart:math';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/util/cacheable.dart';
import 'chains.dart';
import 'eth_rpc.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/series_binary_search.dart';
import 'package:orchid/api/orchid_eth/abi_encode.dart';
import 'package:orchid/api/orchid_log.dart';

/// Represents the Chainlink EACAggregatorProxy that we use for historical
/// price data.
class Chainlink {
  //
  // Aggregator mainnet contract addresses
  //

  // Aurora: Tracks ETH...

  // Optimism (ETH): Tracks ETH...

  // Ethereum,
  static final eth_usd = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';

  // Avalanche,
  static final avax_usd = '0xff3eeb22b5e3de6e705b44749c2559d704923fd7';

  // BinanceSmartChain,
  static final bnb_usd = '0x14e613ac84a31f709eadbdf89c6cc390fdc9540a';

  // Polygon (MATIC),
  static final matic_usd = '0x7bac85a8a13a4bcd8abb3eb7d6b4d632c5a57676';

  // RSK -- Use btc price?
  static final btc_usd = '0xf4030086522a5beea4988f8ca5b36dbc97bee88c';

  // Gnosis (DAI): Should be stable at $1 or we can track dai-usd here:
  static final dai_usd = '0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9';

  // TODO: Optimize the hint intervals below with better averages
  static Map<Chain, ChainlinkContract> mainnet = {
    // Aurora: Tracks ETH...

    // Optimism (ETH): Tracks ETH...

    // Ethereum,
    Chains.Ethereum: ChainlinkContract(
        address: eth_usd, nominalInterval: Duration(minutes: 30)),

    // Gnosis
    Chains.Gnosis: ChainlinkContract(
        address: dai_usd, nominalInterval: Duration(minutes: 30)),

    // Avalanche,
    Chains.Avalanche: ChainlinkContract(
        address: avax_usd, nominalInterval: Duration(hours: 4)),

    // BinanceSmartChain,
    Chains.BinanceSmartChain: ChainlinkContract(
        address: bnb_usd, nominalInterval: Duration(hours: 2)),

    // Polygon (MATIC),
    Chains.Polygon: ChainlinkContract(
        address: matic_usd, nominalInterval: Duration(hours: 1)),

    // RSK -- Use btc price?
    Chains.RSK: ChainlinkContract(
        address: btc_usd, nominalInterval: Duration(hours: 1)),
  };

  //
  // TODO: No chainlink mainnet sources
  //
  // Fantom (FTM),
  // No oracle on mainnet but there is one that seems active on polygon.
  // See notes in tests.
  //
  // Celo (celo),
  // No oracles found.
  //
  // Telos
  // No oracles found.

  /*
  static List<String> _abi = [
    'function decimals() external view returns (uint8)',
    'function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)',
    'function getRoundData(uint80 roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)',
  ];
   */

  static Future<int> decimals(
      {required Chain chain, required String contract}) async {
    final method = '313ce567';
    var params = [
      {"to": "${contract}", "data": "0x${method}"},
      "latest"
    ];
    String result =
        await EthereumJsonRpc.ethCall(url: chain.providerUrl, params: params);
    log("decimals result = $result");
    return int.parse(Hex.remove0x(result), radix: 16);
  }

  static Future<ChainlinkRoundData> latestRoundData(
      {required Chain chain, required String contract}) async {
    var decimals = await Chainlink.decimals(chain: chain, contract: contract);

    final method = 'feaf968c';
    var params = [
      {
        "to": "${contract}",
        "data": "0x${method}",
      },
      "latest"
    ];

    var result =
        await EthereumJsonRpc.ethCall(url: chain.providerUrl, params: params);
    // log("latestRoundData = $result");

    // Parse the result
    // function getRoundData(uint80 roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    var buff = HexStringBuffer(result);
    BigInt roundId = buff.takeUint80();
    BigInt answer = buff.takeUint256();
    BigInt startedAt = buff.takeUint256();
    BigInt updatedAt = buff.takeUint256();
    BigInt answeredInRound = buff.takeUint80();

    return ChainlinkRoundData(
      decimals: decimals,
      roundId: roundId,
      answer: answer,
      startedAt: startedAt,
      updatedAt: updatedAt,
      answeredInRound: answeredInRound,
    );
  }

  static Future<ChainlinkRoundData> getRoundDataFor({
    required Chain chain,
    required String contract,
    required int decimals,
    required int phase,
    required int round,
  }) async {
    final proxyRoundId = (BigInt.from(phase) << 64) | BigInt.from(round);
    // log("proxy round id = $proxyRoundId");
    return await getRoundData(
      chain: chain,
      contract: contract,
      decimals: decimals,
      roundId: proxyRoundId,
    );
  }

  static Cache<String, ChainlinkRoundData> _roundCache =
      Cache(name: 'chainlink round data');

  static Future<ChainlinkRoundData> getRoundData({
    required Chain chain,
    required String contract,
    required BigInt roundId,
    required int decimals,
  }) async {
    final key = contract + roundId.toString();
    _getRoundData(_) => getRoundDataImpl(
        chain: chain, contract: contract, roundId: roundId, decimals: decimals);
    return _roundCache.get(key: key, producer: _getRoundData);
  }

  // function getRoundData(uint80 roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  static Future<ChainlinkRoundData> getRoundDataImpl({
    required Chain chain,
    required String contract,
    required BigInt roundId,
    required int decimals,
  }) async {
    final method = '9a6fc8f5';
    var params = [
      {
        "to": "${contract}",
        "data": "0x${method}"
            "${AbiEncode.uint80(roundId)}"
      },
      "latest"
    ];

    var result =
        await EthereumJsonRpc.ethCall(url: chain.providerUrl, params: params);
    // log("getRoundData = $result");

    // Parse the result
    // function getRoundData(uint80 roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    var buff = HexStringBuffer(result);
    BigInt id = buff.takeUint80();
    BigInt answer = buff.takeUint256();
    BigInt startedAt = buff.takeUint256();
    BigInt updatedAt = buff.takeUint256();
    BigInt answeredInRound = buff.takeUint80();

    return ChainlinkRoundData(
      decimals: decimals,
      roundId: id,
      answer: answer,
      startedAt: startedAt,
      updatedAt: updatedAt,
      answeredInRound: answeredInRound,
    );
  }

  /// Fetch daily historical token prices for the native (gas) token for the chain.
  /// If historical pricing is not available this method will return null.
  /// If data for individual days is missing the list will contains nulls.
  static Future<List<TokenPrice?>?> historicalTokenPrice(
      {required Chain chain, required int days, int withinHours = 6}) async {
    final contract = mainnet[chain];
    if (contract == null) {
      return null;
    }

    // The mainnet contracts are on Ethereum mainnet
    final contractChain = Chains.Ethereum;
    var latestRoundData;
    try {
      latestRoundData = await Chainlink.latestRoundData(
          chain: contractChain, contract: contract.address);
    } catch (err) {
      log("error fetching latest round data: $err");
      return null;
    }

    int decimals = latestRoundData.decimals;
    final latestProxyRoundId = latestRoundData.roundId;
    final latestPhase = (latestProxyRoundId >> 64).toInt();
    final latestRound =
        (latestProxyRoundId & BigInt.from(pow(2, 16) - 1)).toInt();

    int totalLookups = 0;
    final intervalsPerDay = 24 * 60 / contract.nominalInterval.inMinutes;
    final search = SeriesBinarySearch<ChainlinkRoundData>(
      minIndex: 0,
      maxIndex: latestRound,
      startIndex: latestRound,
      valueForIndex: (i) async {
        totalLookups += 1;
        // print("value for index: $i");
        final roundData = await Chainlink.getRoundDataFor(
          decimals: decimals,
          chain: contractChain,
          contract: contract.address,
          phase: latestPhase,
          round: i,
        );
        return roundData;
      },
      seriesExpectedInterval: intervalsPerDay.toInt(),
    );

    List<ChainlinkRoundData?> list = [];
    int missing = 0;
    for (var i = 0; i < days; i++) {
      var range = ChainlinkRoundDateTimeComparable(
        date: DateTime.now().subtract(Duration(days: i)),
        within: Duration(hours: withinHours),
      );
      var found = await search.findNext(range);
      if (found != null) {
        // print("found = $found");
        list.insert(0, found);
      } else {
        missing += 1;
        print("MISSING! date = ${range.compare.date}");
        list.insert(0, null);
      }
    }
    print("totalLooksups = $totalLookups, total missing = $missing");
    return list
        .map((e) => e == null
            ? null
            : TokenPrice(
                date: e.date,
                priceUSD: e.price,
                tokenType: chain.nativeCurrency))
        .toList();
  }
}

class TokenPrice {
  final DateTime date;
  final double priceUSD;
  final TokenType tokenType;

  TokenPrice(
      {required this.date, required this.tokenType, required this.priceUSD});
}

class ChainlinkRoundData {
  final int decimals;
  final BigInt roundId;
  final BigInt answer;
  final BigInt startedAt;
  final BigInt updatedAt;
  final BigInt answeredInRound;

  DateTime get date =>
      DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt() * 1000);

  double get price => answer.toDouble() / pow(10, decimals);

  ChainlinkRoundData({
    required this.decimals,
    required this.roundId,
    required this.answer,
    required this.startedAt,
    required this.updatedAt,
    required this.answeredInRound,
  });

  @override
  String toString() {
    return 'ChainlinkRoundData{updatedAt: $date, price: $price}';
  }
}

class ChainlinkContract {
  final String address;

  /// The nominal periodic oracle interval, i.e. the period when zero volatility.
  final Duration nominalInterval;

  ChainlinkContract({required this.address, required this.nominalInterval});
}

/// Compare chainlink data rounds by date.
class ChainlinkRoundDateTimeComparable extends Comparable<ChainlinkRoundData> {
  final DateTimeComparable compare;

  ChainlinkRoundDateTimeComparable(
      {required DateTime date, required Duration within})
      : this.compare = DateTimeComparable(date: date, within: within);

  @override
  int compareTo(ChainlinkRoundData other) {
    return compare.compareTo(other.date);
  }
}
