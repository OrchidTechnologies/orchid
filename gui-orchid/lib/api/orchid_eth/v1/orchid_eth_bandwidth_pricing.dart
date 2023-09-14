import 'package:orchid/api/orchid_eth/eth_rpc.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/api/pricing/usd.dart';
import '../chains.dart';

class OrchidBandwidthPricing {
  static SingleCache<USD> _bandwidthPriceCache =
      SingleCache(duration: Duration(seconds: 60), name: "bandwidth price");

  /// Get the Chainlink bandwidth price oracle value
  static Future<USD> getBandwidthPrice({bool refresh = false}) async {
    return _bandwidthPriceCache.get(
        producer: _fetchBandwidthPrice, refresh: refresh);
  }

  /// Get the Chainlink bandwidth price oracle value
  // curl $url -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_call","params":[{"to": "0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0", "data": "0x50d25bcd"}, "latest"],"id":1}'
  static Future<USD> _fetchBandwidthPrice() async {
    var contractAddress = '0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0';
    var latestAnswerHash = '0x50d25bcd';

    // construct the abi encoded eth_call
    var params = [
      {"to": contractAddress, "data": latestAnswerHash},
      "latest"
    ];

    String result = await EthereumJsonRpc.ethCall(
        url: Chains.Ethereum.providerUrl, params: params);
    if (!result.startsWith("0x")) {
      log("Error result: $result");
      throw Exception();
    }

    // Parse the results:
    var buff = HexStringBuffer(result);
    BigInt value = buff.takeUint256();
    return USD(value.toDouble() / 1e5);
  }
}
