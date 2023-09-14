import 'dart:math';
import 'package:orchid/util/cacheable.dart';
import 'chains.dart';
import 'eth_rpc.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/series_binary_search.dart';

class HistoricalGasPrices {
  static Future<BigInt> getLatestBlockNo(Chain chain) async {
    final result = await EthereumJsonRpc.ethJsonRpcCall(
      method: 'eth_blockNumber',
      url: chain.providerUrl,
    );
    // log("result = $result");
    return BigInt.parse(Hex.remove0x(result), radix: 16);
  }

  static Cache<String, GasPrice> _roundCache =
      Cache(name: 'historical gas price');

  static Future<GasPrice> getGasPriceForBlock(Chain chain, int blockno) async {
    final key = chain.chainId.toString() + blockno.toString();
    _getRoundData(_) => getGasPriceForBlockImpl(chain, blockno);
    return _roundCache.get(key: key, producer: _getRoundData);
  }

  // Get the (EIP1559) base fee gas price in wei.
  static Future<GasPrice> getGasPriceForBlockImpl(
      Chain chain, int blockno) async {
    final result = await EthereumJsonRpc.ethJsonRpcCall(
        method: 'eth_getBlockByNumber',
        url: chain.providerUrl,
        params: [
          Hex.hex(blockno),
          false /*hashes only*/
        ]);
    // log("result = $result");
    final price = Hex.parseBigInt(result['baseFeePerGas']);
    final date = DateTime.fromMillisecondsSinceEpoch(
        Hex.parseInt(result['timestamp']) * 1000);
    return GasPrice(chain: chain, date: date, price: price);
  }

  static Future<List<GasPrice?>?> historicalGasPrices(
      {required Chain chain, required int days, int withinHours = 6}) async {
    final latestBlockNo = await getLatestBlockNo(chain);

    // Note: For EVM compatible chains that are simply not yet EIP1559 we can
    // Note: fall back to reading a full block and finding the median price.
    // Note: Note that neither technique will work on some chains (e.g. Optimism)
    // Note: that do not have normal EVM gas pricing.
    if (!chain.eip1559) {
      return null;
    }

    int totalLookups = 0;
    final blocksPerDay = 24 * 3600 / (max(chain.blocktime, 1));
    final search = SeriesBinarySearch<GasPrice>(
      minIndex: 0,
      maxIndex: latestBlockNo.toInt(),
      startIndex: latestBlockNo.toInt(),
      valueForIndex: (i) async {
        totalLookups += 1;
        final roundData = await getGasPriceForBlock(chain, i);
        return roundData;
      },
      seriesExpectedInterval: blocksPerDay.toInt(),
    );

    List<GasPrice?> list = [];
    int missing = 0;
    for (var i = 0; i < days; i++) {
      var range = GasPriceDateTimeComparable(
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
    return list;
  }

  static void runTests() async {
    var prices;
    prices = await historicalGasPrices(chain: Chains.Ethereum, days: 30);
    // prices = await historicalGasPrices(chain: Chains.Gnosis, days: 30);
    // prices = await historicalGasPrices(chain: Chains.Avalanche, days: 30);
    // prices = await historicalGasPrices(chain: Chains.Polygon, days: 30);
    log("prices = $prices");

    // Does not implement EIP-1559
    // prices = await historicalGasPrices(chain: Chains.RSK, days: 30);

    // Does not implement EIP-1559
    // blocks are active
    // historicalGasPrices(Chains.BinanceSmartChain, 30);

    // Does not seem to implement EIP-1559
    // gas (paid in NEAR) is free right now...
    // low activity - often zero transactions in the block
    // historicalGasPrices(Chains.Aurora, 30);

    // Does not seem to implement EIP-1559
    // one transaction per block
    // L2 gas 0.001 gwei exactly + some L1 fee (how can we see it?)
    // historicalGasPrices(Chains.Optimism, 30);
  }
}

/// A historical gas price
class GasPrice {
  final Chain chain;
  final DateTime date;
  final BigInt price;

  GasPrice({required this.chain, required this.date, required this.price});

  @override
  String toString() {
    return 'GasPrice{date: $date, price: $price}';
  }
}

class GasPriceDateTimeComparable extends Comparable<GasPrice> {
  final DateTimeComparable compare;

  GasPriceDateTimeComparable({required DateTime date, required Duration within})
      : this.compare = DateTimeComparable(date: date, within: within);

  @override
  int compareTo(GasPrice other) {
    return compare.compareTo(other.date);
  }
}
