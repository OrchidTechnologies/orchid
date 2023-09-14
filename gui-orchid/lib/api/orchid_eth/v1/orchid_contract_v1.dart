import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';

class OrchidContractV1 {
  // Lottery contract address (all chains, singleton deployment).
  static var _lotteryContractAddressV1 =
      '0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82';

  // Ganache Testing
  static var _testLotteryContractAddressV1 =
      '0x9a9bD72080219Ef38deE01bCBFC91A9C0Ffe95C6';

  static String get lotteryContractAddressV1 {
    // if (OrchidUserParams().test) {
    //   return _testLotteryContractAddressV1;
    // }
    return OrchidUserConfig()
        .getUserConfig()
        .evalStringDefault("lottery", _lotteryContractAddressV1);
  }

  /// Indicates that one or more of the contract addresses have been overridden
  static bool get contractOverridden {
    return lotteryContractAddressV1 != _lotteryContractAddressV1;
  }

  // The earliest block from which we look for events on chain for this contract.
  // TODO:
  static int startBlock = 0;

  static String createEventHashV1 =
      // Create(address,address,address)
      '0xb224da6575b2c2ffd42454faedb236f7dbe5f92a0c96bb99c0273dbe98464c7e';

  static String readMethodHash = '5185c7d7';
  static String moveMethodHash = '987ff31c';

  static int gasCostToRedeemTicket = 100000;
  static int lotteryMoveMaxGas = 175000;
  static int createAccountMaxGas = lotteryMoveMaxGas;
  static int lotteryPullMaxGas = 150000;
  static int lotteryWarnMaxGas = 50000;

// static lottery_lock_max_gas: number = 50000;
// static lottery_warn_max_gas: number = 50000;
// static lottery_move_max_gas: number = 175000;

// Total max gas used by an add funds operation.
// static add_funds_total_max_gas: number = OrchidContractV1.lottery_move_max_gas;
// static stake_funds_total_max_gas: number = OrchidContractV1.add_funds_total_max_gas;

  static List<String> abi = [
    'event Create(address indexed token, address indexed funder, address indexed signer)',
    'event Update(bytes32 indexed key, uint256 escrow_amount)',
    'event Delete(bytes32 indexed key, uint256 unlock_warned)',
    'function read(address token, address funder, address signer) external view returns (uint256, uint256)',
    'function edit(address signer, int256 adjust, int256 warn, uint256 retrieve) external payable',
  ];
}
