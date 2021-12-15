import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';

import '../orchid_web3_context.dart';

class OrchidContractWeb3V1 {
  final OrchidWeb3Context context;

  OrchidContractWeb3V1(this.context);

  Contract contract() {
    return Contract(
        OrchidContractV1.lotteryContractAddressV1, _lotteryAbi, context.web3);
  }

  static List<String> _lotteryAbi = [
    "event Create(address indexed token, address indexed funder, address indexed signer)",
    "event Update(bytes32 indexed key, uint256 escrow_amount)",
    "event Delete(bytes32 indexed key, uint256 unlock_warned)",
    "function read(address token, address funder, address signer) external view returns (uint256, uint256)",
    "function edit(address signer, int256 adjust, int256 warn, uint256 retrieve) external payable",
  ];
}
