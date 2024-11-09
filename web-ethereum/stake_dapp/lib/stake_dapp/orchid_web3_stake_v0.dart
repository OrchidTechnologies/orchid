import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/dapp/orchid_web3/orchid_erc20.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';

import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:orchid/gui-orchid/lib/api/orchid_eth/abi_encode.dart';
import 'package:orchid/gui-orchid/lib/util/hex.dart';
import 'package:web3dart/crypto.dart';

class OrchidWeb3StakeV0 {
  final OrchidWeb3Context context;
  final Contract _directoryContract;
  final OrchidERC20 _oxt;

  OrchidWeb3StakeV0(this.context)
      : this._directoryContract = Contract(
            OrchidContractV0.directoryContractAddressString,
            OrchidContractV0.directoryAbi,
            context.web3),
        this._oxt = OrchidERC20(context: context, tokenType: Tokens.OXT);

  // Return the total stake for the specified stakee address.
  // This is the aggregate of all stakes for the address as returned by the heft() call.
  Future<Token> orchidGetTotalStake(EthereumAddress stakee) async {
    log("Get stake for: $stakee");
    var result = await _directoryContract.call('heft', [
      stakee.toString(), // 0x ?
    ]);
    log("XXX: heft = $result");
    try {
      return Tokens.OXT.fromIntString(result.toString());
    } catch (err) {
      log("Error parsing heft result: $err");
      return Tokens.OXT.zero;
    }
  }

  // Get the stake for the specified staker and stakee addresses.
  // Note: This method uses getStorageAt to retrieve the stake amount and delay since
  // Note: there is no public method to fetch them for a specific staker/stakee pair.
  Future<StakeResult> orchidGetStakeForStaker({
    required EthereumAddress staker,
    required EthereumAddress stakee,
  }) async {
    BigInt calculateStorageSlot(
        EthereumAddress staker, EthereumAddress stakee) {
      final Uint8List keccakStakerStakee =
          keccak256(tie(staker.bytes, stakee.bytes));
      // 2 is the index of the stakes_ mapping in the Directory contract
      final Uint8List slot =
          keccak256(tie(keccakStakerStakee, BigInt.two.toBytesUint256()));
      return BigInt.parse(hex.encode(slot), radix: 16);
    }

    // Calculate the storage slots for the stake amount and delay
    BigInt stakeSlot = calculateStorageSlot(staker, stakee);
    BigInt amountSlot = stakeSlot + BigInt.two; // `stakeSlot + 2`
    BigInt delaySlot = stakeSlot + BigInt.from(3); // `stakeSlot + 3`

    // Invoke eth_getStorageAt to get the stake amount and delay
    String amount = await _directoryGetStorageAt(amountSlot);
    String delay = await _directoryGetStorageAt(delaySlot);

    return StakeResult(
      Tokens.OXT.fromIntString(amount),
      BigInt.parse(delay),
    );
  }

  // Note: This method uses getStorageAt to retrieve the pending data.
  // Note: There is no public method to fetch this information.
  Future<StakePendingResult> orchidGetPendingWithdrawal({
    required EthereumAddress staker,
    required int index,
  }) async {
    // Calculate the storage slot for the pending withdrawal amount
    BigInt calculatePendingStorageSlot(EthereumAddress staker, int index) {
      // (staker, contract slot index)
      final Uint8List keccakStakerSlot = keccak256(
          tie(staker.value.toBytesUint256(), BigInt.from(4).toBytesUint256()));
      // (array index, slot)
      final Uint8List slot =
          keccak256(tie(BigInt.from(index).toBytesUint256(), keccakStakerSlot));
      return BigInt.parse(hex.encode(slot), radix: 16);
    }

    // Calculate the storage slots for the Pending struct fields
    BigInt pendingSlot = calculatePendingStorageSlot(staker, index);

    // 0: expire_ (uint256)
    // 1: stakee_ (address)
    // 2: amount_ (uint256)
    BigInt expireSlot = pendingSlot;
    BigInt amountSlot = pendingSlot + BigInt.two;
    String expire = await _directoryGetStorageAt(expireSlot);
    log("XXX: pending expire = $expire");
    String amount = await _directoryGetStorageAt(amountSlot);
    log("XXX: pending amount = $amount");

    return StakePendingResult(
      Tokens.OXT.fromIntString(amount),
      BigInt.parse(expire),
    );
  }

  Future<String> _directoryGetStorageAt(BigInt slot) {
    return _directoryContract.provider
        .call('getStorageAt', [_directoryContract.address, Hex.hex(slot)]);
  }

  /// Transfer the int amount from the user to the specified directory address.
  /// Amount won't exceed walletBalance.
  // 'function push(address stakee, uint256 amount, uint128 delay)',
  Future<void> orchidStakePushFunds({
    required OrchidWallet wallet,
    required EthereumAddress stakee,
    required Token amount,
    BigInt? delay,
    ERC20PayableTransactionCallbacks? callbacks,
  }) async {
    delay ??= BigInt.zero;
    // Currently disallow staking delay.
    if (delay != BigInt.zero) {
      throw Exception("Staking delay not allowed.");
    }
    amount.assertType(Tokens.OXT);
    log("Stake funds: amount: $amount, stakee: $stakee, delay: $delay");
    final funder = wallet.address!;
    var walletBalance = await _oxt.getERC20Balance(funder);
    amount = Token.min(amount, walletBalance);

    // Check allowance and skip approval if sufficient.
    // function allowance(address owner, address spender) external view returns (uint256)
    Token oxtAllowance = await _oxt.getERC20Allowance(
      owner: funder,
      spender: OrchidContractV0.lotteryContractAddressV0,
    );
    if (oxtAllowance < amount) {
      log("Stake funds: oxtAllowance increase required: $oxtAllowance < $amount");
      var approveTxHash = await _oxt.approveERC20(
        owner: funder,
        spender: OrchidContractV0.directoryContractAddress,
        amount: amount, // Amount is the new total approval amount
      );
      callbacks?.onApproval(approveTxHash);
      await Future.delayed(Duration(milliseconds: 1000));
    } else {
      log("Stake funds: oxtAllowance sufficient: $oxtAllowance");
    }

    // Do the stake call
    var contract = _directoryContract.connect(context.web3.getSigner());
    log("Stake funds: do push, amount: $amount, stakee: $stakee, delay: $delay");
    TransactionResponse pushTx = await contract.send(
      'push',
      [
        stakee.toString(),
        amount.intValue.toString(),
        delay.toString(),
      ],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitDirectoryPush)),
    );
    callbacks?.onTransaction(pushTx.hash);
  }

  /// Pull funds to the specified index.
  // 'function pull(address stakee, uint256 amount, uint256 index)',
  Future<List<String> /*TransactionId*/ > orchidStakePullFunds({
    required EthereumAddress stakee,
    required Token amount,
    required int index,
  }) async {
    amount.assertType(Tokens.OXT);
    log("Pull funds amount: $amount, stakee: $stakee, index: $index");
    List<String> txHashes = [];

    // Do the pull call
    var contract = _directoryContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'pull',
      [
        stakee.toString(),
        amount.intValue.toString(),
        index.toString(),
      ],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitDirectoryPull)),
    );
    txHashes.add(tx.hash);
    return txHashes;
  }

  // Withdraw from index
  // 'function take(uint256 index, uint256 amount, address payable target)',
  Future<List<String> /*TransactionId*/ > orchidStakeWithdrawFunds({
    required int index,
    required Token amount,
    required EthereumAddress target,
  }) async {
    amount.assertType(Tokens.OXT);
    log("Withdraw funds amount: $amount, target: $target, index: $index");
    List<String> txHashes = [];

    // Do the withdraw call
    var contract = _directoryContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'take',
      [
        index.toString(),
        amount.intValue.toString(),
        target.toString(),
      ],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitDirectoryTake)),
    );
    txHashes.add(tx.hash);
    return txHashes;
  }
}

class StakeResult {
  final Token amount;
  final BigInt delay;

  StakeResult(this.amount, this.delay);

  @override
  String toString() {
    return "StakeResult(amount: $amount, delay: $delay)";
  }
}

class StakePendingResult {
  final Token amount;
  final BigInt expire;

  StakePendingResult(this.amount, this.expire);

  @override
  String toString() {
    return "StakePendingResult(expire: $expire, amount: $amount)";
  }
}
