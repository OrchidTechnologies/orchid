import 'package:orchid/util/hex.dart';
import '../orchid_crypto.dart';

class EthereumTransaction /*extends EthereumTransactionParams*/ {
  final EthereumTransactionParams params;
  final String data;
  final int? nonce;

  EthereumTransaction({
    required this.params,
    required this.data,
    this.nonce,
  });

  Map<String, dynamic> toJson() {
    // Export flat json
    var json = params.toJson();
    json.addAll({'data': data});
    // Exclude nonce if null
    if (nonce != null) {
      json.addAll({
        'nonce': nonce, // decimal int
      });
    }
    return json;
  }

  EthereumTransaction.fromJson(Map<String, dynamic> json)
      // Import from flat json
      : params = EthereumTransactionParams.fromJson(json),
        data = json['data'],
        nonce = json['nonce'];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is EthereumTransaction &&
          runtimeType == other.runtimeType &&
          params == other.params &&
          data == other.data &&
          nonce == other.nonce;

  @override
  int get hashCode =>
      super.hashCode ^ params.hashCode ^ data.hashCode ^ nonce.hashCode;

  @override
  String toString() {
    return 'EthereumTransaction{params: $params, data: $data, nonce: $nonce}';
  }
}

/*
    {
      "txn": {
        "from": "0x00A0844371B32aF220548DCE332989404Fda2EeF",
        "to": "0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b",
        "gas": "0x2ab98", // 175k
        "gasPrice": "0x3b9aca00", // 1e9
        "value": "0xde0b6b3a7640000", // 1e18
        "chainId": 100,
        "data": "0x987ff31c00000000000000000000000000a0844371b32af220548dce332989404fda2eef0000000000000000016345785d8a000000000000000000000000000000000000"
      }
    }
*/
class EthereumTransactionParams {
  final EthereumAddress from;
  final EthereumAddress to;
  final int gas;
  final BigInt gasPrice;
  final BigInt value;
  final int chainId;

  EthereumTransactionParams({
    required this.from,
    required this.to,
    required this.gas,
    required this.gasPrice,
    required this.value,
    required this.chainId,
  });

  Map<String, dynamic> toJson() {
    var json = {
      'from': from.toString(),
      'to': to.toString(),
      'gas': hex(gas),
      'gasPrice': hex(gasPrice),
      'value': hex(value),
      'chainId': chainId, // decimal int
    };
    return json;
  }

  EthereumTransactionParams.fromJson(Map<String, dynamic> json)
      : from = EthereumAddress.from(json['from']),
        to = EthereumAddress.from(json['to']),
        // parse takes 0x for hex
        gas = int.parse(json['gas']),
        gasPrice = BigInt.parse(json['gasPrice']),
        value = BigInt.parse(json['value']),
        chainId = json['chainId'];

  String hex(dynamic val) {
    return Hex.hex(val);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthereumTransactionParams &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          gas == other.gas &&
          gasPrice == other.gasPrice &&
          value == other.value &&
          chainId == other.chainId;

  @override
  int get hashCode =>
      from.hashCode ^
      to.hashCode ^
      gas.hashCode ^
      gasPrice.hashCode ^
      value.hashCode ^
      chainId.hashCode;

  @override
  String toString() {
    return 'EthereumTransactionParams' + (toJson().toString());
  }
}
