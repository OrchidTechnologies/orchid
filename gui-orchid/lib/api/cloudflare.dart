import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

import 'orchid_budget_api.dart';
import 'orchid_crypto.dart';

class CloudFlare {
  // Cloudflare API
  static var url = 'https://cloudflare-eth.com';

  // Lottery contract address on main net
  static var lotteryContractAddress =
      '0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1';

  // The ABI identifier for the `look` method.
  // Note: The first four bytes of the signature hash (Remix can provide this).
  static var lotteryLookMethodHash = '1554ad5d';

  /*
    Example:
    curl https://cloudflare-eth.com -H 'Content-Type: application/json' --data
      '{"jsonrpc":"2.0",
        "method":"eth_call",
        "params":[{
           "to": "0x38cf68E1d19a0b2d2Ba73865E4c85aA1A544C1BF",
           "data": "0x1554ad5d000000000000000000000000405bc10e04e3f487e9925ad5815e4406d78b769e00000000000000000000000040797C3fa232ff87d59e2c3241448C5AC8537D07"},
           "latest"],
        "id":1}'
    Result:
    {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000002b5e3af16b18800000000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000"}
  */
  static Future<LotteryPot> getLotteryPot(
      EthereumAddress funder, EthereumAddress signer) async {
    print("fetch pot for: $funder, $signer");
    // construct the abi encoded eth_call
    var params = '[{'
        '"to": "$lotteryContractAddress", '
        '"data": "0x${lotteryLookMethodHash}${abiEncoded(funder)}${abiEncoded(signer)}"'
        '}, "latest"]';
    var postBody =
        '{"jsonrpc": "2.0", "method": "eth_call", "id": 1, "params": ${params}}';

    //print("post body = $postBody");
    // do the post
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: postBody);

    if (response.statusCode != 200) {
      throw Exception("Error status code: ${response.statusCode}");
    }
    var body = json.decode(response.body);

    if (body['error'] != null) {
      throw Exception("Cloudflare fetch error in response: $body");
    }

    String result = body['result'];
    if (!result.startsWith("0x")) {
      print("Error result: $result");
      throw Exception();
    }

    var buff = HexStringBuffer(result);
    OXT balance = OXT.fromWei(buff.take(64)); // uint128 padded
    OXT deposit = OXT.fromWei(buff.take(64)); // uint128 padded
    //BigInt unlock = buff.take(64); // uint256

    return LotteryPot(balance: balance, deposit: deposit);
  }

  // Pad a 40 character address to 64 characters with no prefix
  static String abiEncoded(EthereumAddress address) {
    return '000000000000000000000000' + address.toString(prefix: false);
  }
}
