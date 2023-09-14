import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log.dart';

import '../orchid_erc20.dart';
import '../orchid_web3_context.dart';

/// Read/write calls used in the dapp.
class OrchidWeb3V0 {
  final OrchidWeb3Context context;
  final Contract _lotteryContract;
  final OrchidERC20 _oxt;

  OrchidWeb3V0(this.context)
      : this._lotteryContract = Contract(
            OrchidContractV0.lotteryContractAddressV0String,
            OrchidContractV0.lotteryAbi,
            context.web3),
        this._oxt = OrchidERC20(context: context, tokenType: Tokens.OXT);

  Chain get chain {
    return context.chain;
  }

  TokenType get fundsTokenType {
    return Tokens.OXT;
  }

  TokenType get gasTokenType {
    return Tokens.ETH;
  }

  /// Transfer the int amount from the user to the specified lottery pot address.
  /// If the total exceeds walletBalance the amount value is automatically reduced.
  Future<List<String> /*TransactionId*/ > orchidAddFunds({
    required OrchidWallet wallet,
    required EthereumAddress signer,
    required Token addBalance,
    required Token addEscrow,
  }) async {
    if (wallet.address == null) {
      throw Exception("Wallet address is null");
    }
    addBalance.assertType(Tokens.OXT);
    addEscrow.assertType(Tokens.OXT);
    var walletBalance = await _oxt.getERC20Balance(wallet.address!);

    // Don't attempt to add more than the wallet balance.
    // This mitigates the potential for rounding errors in calculated amounts.
    var totalOXT = Token.min(addBalance.add(addEscrow), walletBalance);
    log("Add funds signer: $signer, amount: ${totalOXT.subtract(addEscrow)}, escrow: $addEscrow");

    List<String> txHashes = [];

    // Check allowance and skip approval if sufficient.
    // function allowance(address owner, address spender) external view returns (uint256)
    Token oxtAllowance = await _oxt.getERC20Allowance(
      owner: wallet.address!,
      spender: OrchidContractV0.lotteryContractAddressV0,
    );
    if (oxtAllowance < totalOXT) {
      log("XXX: oxtAllowance increase required: $oxtAllowance < $totalOXT");
      var approveTxHash = await _oxt.approveERC20(
          owner: wallet.address!,
          spender: OrchidContractV0.lotteryContractAddressV0,
          amount: totalOXT);
      txHashes.add(approveTxHash);
    } else {
      log("XXX: oxtAllowance sufficient: $oxtAllowance");
    }

    // Do the add call
    var contract = _lotteryContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'push',
      [
        signer.toString(),
        totalOXT.intValue.toString(),
        addEscrow.intValue.toString(),
      ],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitLotteryPush)),
    );
    txHashes.add(tx.hash);
    return txHashes;
  }

  /// Withdraw from balance and escrow to the wallet address.
  Future<String /*TransactionId*/ > orchidWithdrawFunds({
    required EthereumAddress wallet,
    required EthereumAddress signer,
    required LotteryPot pot,
    required Token withdrawBalance,
    required Token withdrawEscrow,
  }) async {
    withdrawBalance.assertType(Tokens.OXT);
    withdrawEscrow.assertType(Tokens.OXT);
    if (withdrawEscrow > pot.unlockedAmount) {
      throw Exception(
          'withdraw escrow exceeds unlocked: $withdrawEscrow, ${pot.unlockedAmount}');
    }

    // Don't take more than the pot values. This check mitigates rounding errors.
    withdrawBalance = Token.min(withdrawBalance, pot.balance);
    withdrawEscrow = Token.min(withdrawEscrow, pot.unlockedAmount);

    final targetAddress = wallet;
    final autoLock = true;

    log('withdrawFunds to: ${targetAddress} amount: ${withdrawBalance}, ${withdrawEscrow}');

    // Do the withdraw call.
    // pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow) external
    var contract = _lotteryContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'pull',
      [
        signer.toString(),
        targetAddress.toString(),
        autoLock,
        withdrawBalance.intValue.toString(),
        withdrawEscrow.intValue.toString(),
      ],
    );
    return tx.hash;
  }

  /// Withdraw from balance and escrow to the wallet address.
  Future<String /*TransactionId*/ > orchidMoveBalanceToEscrow({
    required EthereumAddress signer,
    required LotteryPot pot,
    required Token moveAmount,
  }) async {
    moveAmount.assertType(Tokens.OXT);
    if (moveAmount > pot.balance) {
      throw Exception('Move amount exceeds balance: ${pot.balance}');
    }

    moveAmount = Token.min(moveAmount, pot.balance);

    // Do the move call.
    var contract = _lotteryContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'move',
      [
        signer.toString(),
        moveAmount.intValue.toString(),
      ],
    );
    return tx.hash;
  }

  Future<String /*TransactionId*/ > orchidLockOrWarn({
    required bool isLock,
    required EthereumAddress signer,
  }) async {
    var contract = _lotteryContract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      isLock ? 'lock' : 'warn',
      [
        signer.toString(),
      ],
    );
    return tx.hash;
  }
}
