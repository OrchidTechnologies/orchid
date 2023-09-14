import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/orchid_log.dart';

import '../orchid_platform.dart';

class EthereumJsonRpc {
  /// Make a read-only eth_call to the rpc provider.
  // Note: This method is also used by the PAC seller code.
  static Future<dynamic> ethCall({
    required String url,
    List<Object> params = const [],
  }) async {
    return ethJsonRpcCall(url: url, method: 'eth_call', params: params);
  }

  /// Ethereum json rpc call
  static Future<dynamic> ethJsonRpcCall({
    required String url,
    required String method,
    List<Object> params = const [],
  }) async {
    // construct the abi encoded eth_call
    var postBody = jsonEncode(
        {'jsonrpc': '2.0', 'method': method, 'id': 1, 'params': params});

    // json null params should not be quoted
    postBody = postBody.replaceAll('"null"', 'null');
    logDetail('jsonRPC to $url: postbody = $postBody');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (!OrchidPlatform.isWeb) {
      headers['Referer'] = 'https://account.orchid.com';
    }

    // do the post
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: postBody,
    );

    if (response.statusCode != 200) {
      log('jsonRPC: error response from $url: ${response.body}');
      throw Exception('Error status code: ${response.statusCode}');
    }
    var body = json.decode(response.body);
    if (body['error'] != null) {
      throw Exception('fetch error in response: $body');
    }

    // log('jsonRPC: to $url: result = ${body['result']}');
    return body['result'];
  }
}
