import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/util/units.dart';

class EtherscanIO {
  static var apiKey = "73BIQR3R1ER56V53PSSAPNUTQUFVHCVVVH";
  static var url = 'https://api.etherscan.io/api';
  static var tokenContractAddress =
      '0x53e71f4dec7f0753920a3e039289fdec616ad5b4';
  static var lotteryContractAddress =
      '0xa38b76b4EbD8f10fFC8866F001bB473874B9ee08'; // Main net
  static var lotteryFundMethodSignature =
      '0x3cd5941d0d99319105eba5f5393ed93c883f132d251e56819e516005c5e20dbc';
  static var startBlock = "872000";

  /*
    Get lottery pot funding events for the specified address in descending
    time order (most recent first).

    Example JSON:

     https://api.etherscan.io/api
      ?module=logs
      &action=getLogs
      &fromBlock=8000000&toBlock=latest
      &address=0xd4779b223797ecb6b8833f6f1545f2d94b29219c
      &topic0=0xd6baf52d1a5fcdfc28f52cd8c2b20065e3d2d5354c0384fd85377ad6ae54493d
      &topic1=0x000000000000000000000000accd85a8b3f96cccde5e741fd35ea761cba3f621
      &apikey=73BIQR3R1ER56V53PSSAPNUTQUFVHCVVVH

    {
    "status": "1",
    "message": "OK",
    "result": [
      {
        "address": "0xd4779b223797ecb6b8833f6f1545f2d94b29219c",
        "topics": [
          "0xd6baf52d1a5fcdfc28f52cd8c2b20065e3d2d5354c0384fd85377ad6ae54493d",
          "0x000000000000000000000000accd85a8b3f96cccde5e741fd35ea761cba3f621"
        ],
        "data": "0x0000000000000000000000000000000000000000000000001bc16d674ec8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "blockNumber": "0x7d3075",
        "timeStamp": "0x5d36789f",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0xee44",
        "logIndex": "0xa0",
        "transactionHash": "0x52f6cc0170da633acb9bb0c58265434700ac371df09688175936e6922acc821e",
        "transactionIndex": "0x99"
      },
      {
        "address": "0xd4779b223797ecb6b8833f6f1545f2d94b29219c",
        "topics": [
          "0xd6baf52d1a5fcdfc28f52cd8c2b20065e3d2d5354c0384fd85377ad6ae54493d",
          "0x000000000000000000000000accd85a8b3f96cccde5e741fd35ea761cba3f621"
        ],
        "data": "0x0000000000000000000000000000000000000000000000004563918244f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "blockNumber": "0x7d3db4",
        "timeStamp": "0x5d372ac4",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0xb3ac",
        "logIndex": "0xe1",
        "transactionHash": "0xd42a7d8d76b6a9aa7a601228244a46766aee7fc35ddab1eb1537aee894fc8d83",
        "transactionIndex": "0x42"
      }
    ]
    }
  */
  static Future<List<LotteryPotUpdateEvent>> getLotteryPotUpdateEvents(String signer) async {
    var response = await http.post(url, body: {
      'module': 'logs',
      'action': 'getLogs',
      'fromBlock': startBlock,
      'toBlock': 'latest',
      'address': lotteryContractAddress,
      'topic0': lotteryFundMethodSignature,
      //'topic1' would be the funder address here
      'topic0_2_opr': 'and',
      'topic2': pad64Chars(signer),
      'apikey': apiKey
    });
    if (response.statusCode != 200) {
      print("Error status code: ${response.statusCode}");
      throw new Error();
    }
    var body = json.decode(response.body);

    if (body['message'] == "No records found") {
      return List<LotteryPotUpdateEvent>();
    }
    if (body['message'] != "OK") {
      print("Error message: ${body['message']}");
      throw new Error();
    }
    List<dynamic> result = body['result'];

    List<LotteryPotUpdateEvent> list = result.map((dynamic event) {
      // The first 64char hex data field is the balance
      int start = 2;
      int end = start + 64;
      OXT balance = toOXT("0x"+event['data'].toString().substring(start, end));

      // The second 64char hex data field is the escrow
      start += 64;
      end += 64;
      OXT escrow = toOXT("0x"+event['data'].toString().substring(start, end));

      // ETH timestamp is seconds since epoch
      DateTime timeStamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(event['timeStamp']) * 1000);

      return LotteryPotUpdateEvent(
          balance: balance,
          escrow: escrow,
          blockNumber: event['blockNumber'],
          timeStamp: timeStamp,
          gasPrice: event['gasPrice'],
          gasUsed: event['gasUsed'],
          transactionHash: event['transactionHash']);
    }).toList();

    // Guarantee the results are sorted by time descending.
    list.sort((LotteryPotUpdateEvent a, LotteryPotUpdateEvent b) {
      return -a.timeStamp.compareTo(b.timeStamp);
    });
    return list;
  }

  /// get the Orchid token balance for the specified address.
  static Future<OXT> getTokenBalance(String address) async {
    var response = await http.post(url, body: {
      'module': 'account',
      'action': 'tokenbalance',
      'contractaddress': tokenContractAddress,
      'address': address,
      'tag': 'latest',
      'apikey': apiKey
    });

    if (response.statusCode != 200) {
      print("Error: $response");
      throw new Error();
    }
    var body = json.decode(response.body);
    if (body['message'] != "OK") {
      print("Error: $response");
      throw new Error();
    }
    var balance = body['result'];
    return toOXT(balance);
  }

  static OXT toOXT(String oxtWei) {
    return OXT(BigInt.parse(oxtWei) / BigInt.from(1e18));
  }

  // Pad a 40 character address to 64 characters
  static String pad64Chars(String address) {
    if (address.startsWith("0x")) {
      address = address.substring(2);
    }
    assert(address.length == 40);
    return '0x000000000000000000000000' + address;
  }
}

class LotteryPotUpdateEvent {
  final OXT balance;
  final OXT escrow;
  final String blockNumber;
  final DateTime timeStamp;
  final String gasPrice;
  final String gasUsed;
  final String transactionHash;

  LotteryPotUpdateEvent(
      {this.balance,
      this.escrow,
      this.blockNumber,
      this.timeStamp,
      this.gasPrice,
      this.gasUsed,
      this.transactionHash});
}
