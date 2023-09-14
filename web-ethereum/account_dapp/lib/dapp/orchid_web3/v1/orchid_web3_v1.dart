import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_log.dart';

import '../orchid_web3_context.dart';

/// Read/write calls used in the dapp.
class OrchidWeb3V1 {
  final OrchidWeb3Context context;
  final Contract _lottery;

  OrchidWeb3V1(this.context)
      : this._lottery = Contract(OrchidContractV1.lotteryContractAddressV1, OrchidContractV1.abi, context.web3);

  Chain get chain {
    return context.chain;
  }

  TokenType get fundsTokenType {
    return context.chain.nativeCurrency;
  }

  TokenType get gasTokenType {
    return context.chain.nativeCurrency;
  }

  /// Transfer the amount from the user to the specified lottery pot address.
  /// If the total exceeds walletBalance the balance value is reduced.
  Future<List<String> /*TransactionId*/ > orchidAddFunds({
    required OrchidWallet wallet,
    required EthereumAddress signer,
    required Token addBalance,
    required Token addEscrow,
  }) async {
    if (context.wallet == null) {
      throw Exception('no wallet');
    }
    var walletBalance = await context.wallet!.getBalance();

    // Don't attempt to add more than the wallet balance.
    // This mitigates the potential for rounding errors in calculated amounts.
    var totalPayable = Token.min(addBalance.add(addEscrow), walletBalance);
    log("Add funds signer: $signer, amount: ${totalPayable.subtract(addEscrow)}, escrow: $addEscrow");

    // 'adjust' specifies how much to move from balance to escrow (positive)
    // or escrow to balance (negative)
    // 'retrieve' specifies an amount to extract from balance to the funder address
    var adjust = addEscrow.intValue;
    var warn = BigInt.zero;
    var retrieve = BigInt.zero;

    // This client does not specify a gas price. We will assume that an EIP-1559 wallet
    // will do something appropriate.

    // function edit(address signer, int256 adjust, int256 warn, uint256 retrieve)
    TransactionResponse tx = await _editCall(
      signer: signer,
      adjust: adjust,
      warn: warn,
      retrieve: retrieve,
      totalPayable: totalPayable,
    );
    return [tx.hash];
  }

  /// Withdraw funds by moving the specified withdrawEscrow amount from escrow
  /// to balance in combination with retrieving the sum of withdrawBalance and
  /// withdrawEscrow amount from balance to the current wallet.
  /// If warnDeposit is true and the deposit is non-zero all remaining deposit
  /// will be warned.
  Future<String /*TransactionId*/ > orchidWithdrawFunds({
    required LotteryPot pot,
    required EthereumAddress signer,
    required Token withdrawBalance,
    required Token withdrawEscrow,
    required bool warnDeposit,
  }) async {
    log("orchidWithdrawFunds: balance: $withdrawBalance, escrow: $withdrawEscrow, warn: $warnDeposit");

    if (withdrawBalance > pot.balance) {
      throw Exception('insufficient balance: $withdrawBalance, $pot');
    }
    if (withdrawEscrow > pot.unlockedAmount) {
      throw Exception('insufficient warned: $withdrawEscrow, $pot');
    }
    if (withdrawEscrow.gtZero() && pot.isLocked) {
      throw Exception('pot locked: $withdrawEscrow, $pot');
    }

    // Move the specified amount from deposit to balance
    // This is capped at the warned amount.
    var moveEscrowToBalanceAmount =
        Token.min(withdrawEscrow, pot.warned).intValue;
    // Withdraw the sum
    var retrieve = Token.min(withdrawBalance, pot.balance).intValue +
        moveEscrowToBalanceAmount;
    // Warn more if desired
    var warn = (warnDeposit && pot.deposit.gtZero())
        ? pot.deposit.intValue
        : BigInt.zero;

    // This client does not specify a gas price. We will assume that an EIP-1559 wallet
    // will do something appropriate.

    // positive adjust moves from balance to escrow
    final moveBalanceToEscrowAmount = -moveEscrowToBalanceAmount;
    TransactionResponse tx = await _editCall(
      signer: signer,
      adjust: moveBalanceToEscrowAmount,
      warn: warn,
      retrieve: retrieve,
    );
    return tx.hash;
  }

  /// If positive, netPayable indicates net payable amount from the wallet to the
  /// contract. If negative the netPayable indicates the withdraw amount that will
  /// be recieved back to the wallet.
  /// If adjustAmount is positive funds move from balance to deposit;
  /// If adjustAmount is negative funds move from deposit to balance.
  /// warnAmount may be positive or negative to indicate a change in the warned amount.
  /// Note that when funds are recovered from deposit the warned amount is automatically decreased.
  Future<String /*TransactionId*/ > orchidEditFunds({
    required OrchidWallet wallet,
    required EthereumAddress signer,
    required LotteryPot pot,
    required Token netPayable,
    required Token adjustAmount,
    required Token warnAmount,
  }) async {
    log("orchidEditFunds: netPayable: $netPayable, adjustAmount: $adjustAmount, warnAmount: $warnAmount ");

    // check payable
    if (netPayable > wallet.balance!) {
      throw Exception('insufficient wallet balance: ');
    }
    // check adjust
    //...

    // check warn
    if (warnAmount.ltZero()) {
      final warnSubtract = -warnAmount;
      if (warnSubtract > pot.warned) {
        throw Exception(
            'attempt to un-warn more than currently warned: $warnAmount, $pot');
      }
    }
    // The contract doesn't care if the warned value is greater than the deposit.
    // if (warnAmount.gtZero()) { }

    final retrieve = netPayable.lteZero() ? -netPayable.intValue : BigInt.zero;
    final pay = netPayable.gtZero() ? netPayable : null;

    TransactionResponse tx = await _editCall(
      signer: signer,
      adjust: adjustAmount.intValue,
      warn: warnAmount.intValue,
      retrieve: retrieve,
      totalPayable: pay,
    );
    return tx.hash;
  }

  // function edit(address signer, int256 adjust, int256 warn, uint256 retrieve)
  // positive adjust moves from balance to escrow
  Future<TransactionResponse> _editCall({
    required EthereumAddress signer,
    required BigInt adjust,
    required BigInt warn,
    required BigInt retrieve,
    Token? totalPayable,
  }) async {
    var contract = _lottery.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'edit',
      [
        signer.toString(),
        adjust.toString(),
        warn.toString(),
        retrieve.toString(),
      ],
      totalPayable != null
          ? TransactionOverride(value: totalPayable.intValue)
          : TransactionOverride(),
    );
    return tx;
  }
}
