import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';

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
    _assertOXT(addBalance);
    _assertOXT(addEscrow);
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

  /*
  /// Transfer the int amount from the user to the specified lottery pot address.
  /// If the total exceeds walletBalance the amount value is automatically reduced.
  async orchidAddFunds(
    funder: EthAddress, signer: EthAddress, amount: LotFunds, escrow: LotFunds, wallet: Wallet
  ): Promise<string> {
    //return fakeTx(false);

    // If approvalHash is provided it will be supplied to the transaction monitor as part of a
    // the composite Orchid transaction.
    async function doFundTx(approvalHash: string | null) {
      return new Promise<string>(function (resolve, reject) {
        thisCapture.lotteryContract.methods.push(
          signer,
          total.intValue.toString(),
          escrow.intValue.toString()
        ).send({
          from: funder,
          gas: OrchidContractMainNetV0.lottery_push_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash: any) => {
            console.log("doFundTx: Fund hash: ", hash);
            OrchidAPI.shared().transactionMonitor.add(
              new OrchidTransaction(new Date(), OrchidTransactionType.AddFunds, thisCapture.chainId,
                approvalHash ? [approvalHash, hash] : [hash])
            );
          })
          .on('confirmation', (confirmationNumber: any, receipt: any) => {
            console.log("doFundTx: Fund confirmation", confirmationNumber, JSON.stringify(receipt));
            // Wait for confirmations on the funding tx.
            if (confirmationNumber >= thisCapture.requiredConfirmations) {
              const hash = receipt['transactionHash'];
              resolve(hash);
            } else {
              console.log("doFundTx: waiting for more confirmations...");
            }
          })
          .on('error', (err: any) => {
            console.log("doFundTx: Fund error: ", JSON.stringify(err));
            reject(err['message']);
          });
      });
    }

    // Check allowance and skip approval if sufficient.
    const oxtAllowance = this.fundsTokenType.fromIntString(
      await this.tokenContract.methods.allowance(funder, OrchidContractMainNetV0.lottery_addr()).call());
    let approvalHash = oxtAllowance.lt(total) ? await doApproveTx() : null;

    // Introduce a short artificial delay before issuing the second tx
    // Issue: We have had reports of problems where only one dialog is presented to the user.
    // Issue: Trying this to see if it mitigates any race conditions in the wallet.
    await new Promise(r => setTimeout(r, 1000));

    // The UI monitors the funding tx.
    return doFundTx(approvalHash);
  }

   */

  /*
  /// Withdraw funds by moving the specified withdrawEscrow amount from escrow
  /// to balance in combination with retrieving the sum of withdrawBalance and
  /// withdrawEscrow amount from balance to the current wallet.
  /// If warnDeposit is true and the deposit is non-zero all remaining deposit
  /// will be warned.
  Future<String /*TransactionId*/ > orchidWithdrawFunds({
    @required LotteryPot pot,
    @required EthereumAddress signer,
    @required Token withdrawBalance,
    @required Token withdrawEscrow,
    @required bool warnDeposit,
  }) async {
    log("orchidWithdrawFunds: balance: $withdrawBalance, escrow: $withdrawEscrow, warn: $warnDeposit");

    if (withdrawBalance > pot.balance) {
      throw Exception('insufficient balance: $withdrawBalance, $pot');
    }
    if (withdrawEscrow > pot.warned) {
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
   */

  void _assertOXT(Token token) {
    if (token.type != TokenTypes.OXT) {
      throw Exception("Token type is not OXT: $token");
    }
  }
}
