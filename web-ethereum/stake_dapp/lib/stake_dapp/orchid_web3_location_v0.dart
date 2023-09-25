import 'dart:typed_data';

import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/gui-orchid/lib/util/hex.dart';

class OrchidWeb3LocationV0 {
  final OrchidWeb3Context context;
  final Contract _locationContract;

  OrchidWeb3LocationV0(this.context)
      : this._locationContract = Contract(
            OrchidContractV0.locationContractAddressString,
            OrchidContractV0.locationAbi,
            context.web3);

  //  'function look(address target)
  //    external view returns (uint256, bytes memory, bytes memory, bytes memory)',
  //   return (location.set_, location.url_, location.tls_, location.gpg_);
  Future<Location?> orchidLook(EthereumAddress stakee) async {
    log("Get stake location info for: $stakee");
    var result = await _locationContract.call('look', [
      stakee.toString(),
    ]);
    // log("XXX: look = $result");
    try {
      final seti = int.parse(result[0].toString());
      if (seti == 0) {
        return null;
      }
      final set = DateTime.fromMillisecondsSinceEpoch(seti * 1000);
      final url = Hex.decodeString(result[1].toString());
      final tls = result[2].toString();
      return Location(set: set, url: url, tls: tls);
    } catch (err, stack) {
      log("Error in orchidLook: $err, $stack");
      return null;
    }
  }

  // move(bytes calldata url, bytes calldata tls, bytes calldata gpg)
  Future<List<String> /*TransactionId*/ > orchidMove({
    required Uint8List url,
    required Uint8List tls,
  }) async {
    log("Move location: url: $url, tls: $tls");
    var contract = _locationContract.connect(context.web3.getSigner());
    final gpg = Uint8List(0);
    TransactionResponse tx = await contract.send(
      'move',
      [url, tls, gpg],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitLocationMove)),
    );
    return [tx.hash];
  }

  // function poke()
  Future<List<String> /*TransactionId*/ > orchidPoke() async {
    log("Poke location");
    var contract = _locationContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'poke',
      [],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitLocationPoke)),
    );
    return [tx.hash];
  }
}

class Location {
  final DateTime set;
  final String url;
  final String tls;

  // final String gpg;

  Location({
    required this.set,
    required this.url,
    required this.tls,
    // required this.gpg,
  });

  @override
  String toString() {
    return 'Location{set: $set, url: $url, tls: $tls}';
  }
}
