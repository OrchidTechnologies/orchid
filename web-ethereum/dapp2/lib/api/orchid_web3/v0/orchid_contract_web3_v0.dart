import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';

import '../orchid_web3_context.dart';

class OrchidContractWeb3V0 {
  final OrchidWeb3Context context;

  OrchidContractWeb3V0(this.context);

  Contract contract() {
    return Contract(
        OrchidContractV0.lotteryContractAddressV0, _lotteryAbi, context.web3);
  }

  static List<String> _lotteryAbi = [
    "event Update(address indexed funder, address indexed signer, uint128 amount, uint128 escrow, uint256 unlock)",
    "event Create(address indexed funder, address indexed signer)",
    "event Bound(address indexed funder, address indexed signer)",

    "function look(address funder, address signer) external view returns (uint128, uint128, uint256, address, bytes32, bytes memory)",
    "function push(address signer, uint128 total, uint128 escrow)",
    "function move(address signer, uint128 amount)",
    "function warn(address signer)",
    "function lock(address signer)",
    "function pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow)",
    "function yank(address signer, address payable target, bool autolock)",
  ];
}
