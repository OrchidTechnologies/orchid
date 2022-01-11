import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';

import '../../orchid_budget_api.dart';
import '../orchid_erc20.dart';
import '../orchid_web3_context.dart';
import 'orchid_contract_web3_v0.dart';

/// Read/write calls used in the dapp.
class OrchidWeb3V0 {
  final OrchidWeb3Context context;
  final Contract _lotteryContract;
  final OrchidERC20 _oxt;

  OrchidWeb3V0(this.context)
      : this._lotteryContract = OrchidContractWeb3V0(context).lotteryContract(),
        this._oxt = OrchidERC20(context: context, tokenType: TokenTypes.OXT);

  Chain get chain {
    return context.chain;
  }

  TokenType get fundsTokenType {
    return TokenTypes.OXT;
  }

  TokenType get gasTokenType {
    return TokenTypes.ETH;
  }

  /// Transfer the int amount from the user to the specified lottery pot address.
  /// If the total exceeds walletBalance the amount value is automatically reduced.
  Future<List<String> /*TransactionId*/ > orchidAddFunds({
    OrchidWallet wallet,
    EthereumAddress signer,
    Token addBalance,
    Token addEscrow,
  }) async {
    addBalance.assertType(TokenTypes.OXT);
    addEscrow.assertType(TokenTypes.OXT);
    var walletBalance = await _oxt.getERC20Balance(wallet.address);

    // Don't attempt to add more than the wallet balance.
    // This mitigates the potential for rounding errors in calculated amounts.
    var totalOXT = Token.min(addBalance.add(addEscrow), walletBalance);
    log("Add funds signer: $signer, amount: ${totalOXT.subtract(addEscrow)}, escrow: $addEscrow");

    List<String> txHashes = [];

    // Check allowance and skip approval if sufficient.
    // function allowance(address owner, address spender) external view returns (uint256)
    Token oxtAllowance = await _oxt.getERC20Allowance(
      owner: wallet.address,
      spender: OrchidContractV0.lotteryContractAddressV0,
    );
    if (oxtAllowance < totalOXT) {
      log("XXX: oxtAllowance increase required: $oxtAllowance < $totalOXT");
      var approveTxHash = await _oxt.approveERC20(
          owner: wallet.address,
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
    );
    txHashes.add(tx.hash);
    return txHashes;
  }

  /// Withdraw from balance and escrow to the wallet address.
  Future<String /*TransactionId*/ > orchidWithdrawFunds({
    EthereumAddress wallet,
    EthereumAddress signer,
    LotteryPot pot,
    Token withdrawBalance,
    Token withdrawEscrow,
  }) async {
    withdrawBalance.assertType(TokenTypes.OXT);
    withdrawEscrow.assertType(TokenTypes.OXT);
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
    EthereumAddress signer,
    LotteryPot pot,
    Token moveAmount,
  }) async {
    moveAmount.assertType(TokenTypes.OXT);
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
/*
  async orchidLock(_: LotteryPot, funder: EthAddress, signer: EthAddress): Promise<string> {
    return this.evalOrchidTx(
      this.lotteryContract.methods.lock(signer).send({
        from: funder,
        gas: OrchidContractMainNetV0.lottery_lock_max_gas
      }), OrchidTransactionType.Lock
    );
  }

  /// Start the unlock / warn time period (one day in the future).
  async orchidUnlock(_: LotteryPot, funder: EthAddress, signer: EthAddress): Promise<string> {
    return this.evalOrchidTx(
      this.lotteryContract.methods.warn(signer).send({
        from: funder,
        gas: OrchidContractMainNetV0.lottery_warn_max_gas
      }), OrchidTransactionType.Unlock
    );
  }


   */
}
