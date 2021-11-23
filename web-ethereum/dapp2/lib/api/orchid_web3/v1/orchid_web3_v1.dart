
import 'package:flutter_web3/flutter_web3.dart' as flutter_web3;
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';

import '../orchid_web3_context.dart';
import 'orchid_contract_web3_v1.dart';

/// Read/write calls used in the dapp.
class OrchidWeb3V1 {
  final OrchidWeb3Context context;
  final flutter_web3.Contract _lottery;

  final int version = 1;

  OrchidWeb3V1(this.context)
      : this._lottery = OrchidContractWeb3V1(context).contract();

  Chain get chain {
    return context.chain;
  }

  TokenType get fundsTokenType {
    return context.chain.nativeCurrency;
  }

  TokenType get gasTokenType {
    return context.chain.nativeCurrency;
  }

  int requiredConfirmations = 2;

  // used in market conditions
  Future<Token> getAccountCreationGasRequired() {
    // TODO: implement getAccountCreationGasRequired
    throw UnimplementedError();
  }

  Future<Token> getGasPrice() {
    // TODO: implement getGasPrice
    throw UnimplementedError();
  }

  /// Transfer the int amount from the user to the specified lottery pot address.
  /// If the total exceeds walletBalance the amount value is automatically reduced.
  Future< /*TransactionId*/ String> orchidAddFunds(
      {OrchidWallet wallet,
      EthereumAddress signer,
      Token addBalance,
      Token addEscrow}) async {
    //return fakeTx(false);

    var nativeCurrency = context.chain.nativeCurrency;
    var walletBalance = wallet.balances[nativeCurrency];
    if (walletBalance == null) {
      throw Exception('Wallet balance not initialized: $wallet');
    }

    // Don't attempt to add more than the wallet balance.
    // This mitigates the potential for rounding errors in calculated amounts.
    var total = Token.min(addBalance.add(addEscrow), walletBalance);
    log("Add funds signer: $signer, amount: ${total.subtract(addEscrow)}, escrow: $addEscrow");

    // 'adjust' specifies how much to move from balance to escrow (positive)
    // or escrow to balance (negative)
    // 'retrieve' specifies an amount to extract from balance to the funder address
    var adjust = addEscrow.intValue;
    var warn = BigInt.zero;
    var retrieve = BigInt.zero;

    // This client does not specify a gas price. We will assume that an EIP-1559 wallet
    // will do something appropriate.

    // function edit(address signer, int256 adjust, int256 warn, uint256 retrieve) {
    var contract = _lottery.connect(context.web3.getSigner());

    var tx = await contract.send(
      'edit',
      [
        signer.toString(),
        adjust.toString(),
        warn.toString(),
        retrieve.toString(),
      ],
      TransactionOverride(value: total.intValue),
    );
    log("waiting for tx: $tx");
    flutter_web3.TransactionReceipt txResult =
        await tx.wait(requiredConfirmations);
    log("result = $txResult");

    return txResult.transactionHash;

    /* .send({
      from: funder,
      gas: OrchidContractV1.lottery_move_max_gas,
      gasPrice: gasPrice,
      value: total.intValue.toString(),
    })
        .on("transactionHash", (hash: any) => {
    console.log("Fund hash: ", hash);
    OrchidAPI.shared().transactionMonitor.add(
    new OrchidTransaction(new Date(), OrchidTransactionType.AddFunds, thisCapture.chainId, [hash]));
    })
        .on('confirmation', (confirmationNumber: any, receipt: any) => {
    console.log("Fund confirmation", confirmationNumber, JSON.stringify(receipt));
    // Wait for confirmations on the funding tx.
    if (confirmationNumber >= thisCapture.requiredConfirmations) {
    const hash = receipt['transactionHash'];
    resolve(hash);
    } else {
    console.log("waiting for more confirmations...");
    }
    })
        .on('error', (err: any) => {
    console.log("Fund error: ", JSON.stringify(err));
    reject(err['message']);
    });
        */
  }

  Future<LotteryPot> orchidGetLotteryPot(
      {OrchidWallet funder, EthereumAddress signer}) {
    // TODO: implement orchidGetLotteryPot
    throw UnimplementedError();
  }

  Future< /*TransactionId*/ String> orchidLock(
      LotteryPot pot, EthereumAddress funder, EthereumAddress signer) {
    // TODO: implement orchidLock
    throw UnimplementedError();
  }

  Future< /*TransactionId*/ String> orchidMoveFundsToEscrow(
      {OrchidWallet funder,
      EthereumAddress signer,
      Token amount,
      Token potBalance}) {
    // TODO: implement orchidMoveFundsToEscrow
    throw UnimplementedError();
  }

  Future< /*TransactionId*/ String> orchidUnlock(
      LotteryPot pot, EthereumAddress funder, EthereumAddress signer) {
    // TODO: implement orchidUnlock
    throw UnimplementedError();
  }

  Future< /*TransactionId*/ String> orchidWithdrawFunds(
      {OrchidWallet funder,
      EthereumAddress signer,
      EthereumAddress targetAddress,
      Token amount,
      Token potBalance}) {
    // TODO: implement orchidWithdrawFunds
    throw UnimplementedError();
  }

  Future< /*TransactionId*/ String> orchidWithdrawFundsAndEscrow(
      {LotteryPot pot, EthereumAddress targetAddress}) {
    // TODO: implement orchidWithdrawFundsAndEscrow
    throw UnimplementedError();
  }

// orchidGetSigners(wallet: Wallet): Promise<Signer []>
// orchidGetSignerKeys(): Web3Wallet
// orchidCreateSigner(wallet: Wallet): Signer

// orchidStakeFunds(funder: EthAddress, stakee: EthAddress, amount: LotFunds, walletAddress: Wallet, delay: BigInt): Promise<string>
// orchidGetStake(stakee: EthAddress): Promise<LotFunds>
// orchidReset(funder: Wallet): Promise<string>
// getLotteryUpdateEvents(funder: EthAddress, signer: EthAddress): Promise<LotteryPotUpdateEvent[]>
// marketConditions: MarketConditionsSource
/*
  async orchidGetSigners(wallet: Wallet): Promise<Signer []> {
    if (getParam("no_signers")) {
      return [];
    }

    let events = await this.lotteryContract.getPastEvents('Create', {
      filter: {funder: wallet.address},
      fromBlock: OrchidContractV1.startBlock,
      toBlock: 'latest'
    });
    let signerAddresses = events.map(e => {
      return e.returnValues['signer']
    });
    console.log("orchidGetSigners v1: orchid signers: ", signerAddresses);

    let signerKeys = this.orchidGetSignerKeys() as EthereumKey [];
    return OrchidEthereumApiV0Impl.addKeysToSigners(signerAddresses, signerKeys, wallet);
  }

  /// Get the Orchid signer keys wallet in local storage.
  orchidGetSignerKeys(): Web3Wallet {
    return OrchidEthereumApiV0Impl.orchidGetSignerKeys(this.web3);
  }

  /// Create a new signer keypair and save it in the Orchid signer keys wallet in local storage.
  orchidCreateSigner(wallet: Wallet): Signer {
    return OrchidEthereumApiV0Impl.orchidCreateSigner(this.web3, wallet);
  }

  /// Transfer the int amount from the user to the specified directory address.
  /// Amount won't exceed walletBalance.
  async orchidStakeFunds(
    funder: EthAddress, stakee: EthAddress, amount: LotFunds, wallet: Wallet, delay: BigInt
  ): Promise<string> {
    throw Error("unimplemented")
  }

  async orchidGetStake(stakee: EthAddress): Promise<LotFunds> {
    throw Error("unimplemented")
  }

  evalOrchidTx<T>(promise: PromiEvent<T>, type: OrchidTransactionType): Promise<string> {
    return OrchidEthereumApiV0Impl.evalOrchidTx(promise, type, this.chainId);
  }

  /// Move `amount` from balance to escrow, not exceeding `potBalance`.
  async orchidMoveFundsToEscrow(
    funder: EthAddress, signer: EthAddress, amount: LotFunds, potBalance: LotFunds): Promise<string> {

    console.log(`moveFunds amount: ${amount.toString()}`);

    // Don't take more than the pot balance. This check mitigates rounding errors.
    amount = min(amount, potBalance);

    // positive adjust moves from balance to escrow
    const adjust = BigInt(amount.intValue);
    const retrieve = BigInt.zero;
    const warn = BigInt.zero;

    return this.evalOrchidTx(
      this.lotteryContract.methods
        .edit(signer, adjust.toString(), warn.toString(), retrieve.toString())
        .send({
          from: funder,
          gas: OrchidContractV1.lottery_move_max_gas,
        }), OrchidTransactionType.MoveFundsToEscrow
    );
  }

  /// For v1 the target address must be the funder address or an error will be thrown.
  async orchidWithdrawFunds(
    funder: EthAddress, signer: EthAddress, targetAddress: EthAddress, amount: LotFunds, potBalance: LotFunds
  ): Promise<string> {
    if (funder !== targetAddress) {
      throw Error("orchdiWithdrawFunds: v1 contract target address must be funder.");
    }

    // Don't take more than the pot balance. This check mitigates rounding errors.
    amount = min(amount, potBalance);
    console.log(`withdrawFunds to: ${targetAddress} amount: ${amount}`);

    const adjust = BigInt.zero;
    const warn = BigInt.zero;
    const retrieve = amount.intValue;

    // function edit(address signer, int256 adjust, int256 warn, uint256 retrieve) {
    return this.evalOrchidTx(
      this.lotteryContract.methods
        .edit(signer, adjust.toString(), warn.toString(), retrieve.toString())
        .send({
          from: funder,
          gas: OrchidContractV1.lottery_pull_amount_max_gas,
        }), OrchidTransactionType.WithdrawFunds
    );
  }

  /// For v1 the target address must be the funder address or an error will be thrown.
  async orchidWithdrawFundsAndEscrow(pot: LotteryPot, targetAddress: EthAddress): Promise<string> {
    const funder = pot.signer.wallet.address;
    const signer = pot.signer.address;

    if (funder !== targetAddress) {
      throw Error("orchdiWithdrawFunds: v1 contract target address must be funder.");
    }

    // adjust = negative escrow (move from escrow->balance)
    const adjust = BigInt(pot.escrow.intValue).multiply(-1);
    const retrieve = BigInt(pot.balance.add(pot.escrow).intValue);
    const warn = BigInt.zero;

    return this.evalOrchidTx(
      this.lotteryContract.methods
        .edit(signer, adjust.toString(), warn.toString(), retrieve.toString())
        .send({
          from: funder,
          gas: OrchidContractV1.lottery_pull_amount_max_gas,
        }), OrchidTransactionType.WithdrawFunds
    );
  }

  // "Warn" (unlock) the full escrow amount or whatever fraction of it remains un-warned.
  // This starts the unlock / warn time period (one day in the future).
  async orchidUnlock(pot: LotteryPot, funder: EthAddress, signer: EthAddress): Promise<string> {

    const adjust = BigInt.zero;
    const retrieve = BigInt.zero;
    // warn amount is the full escrow minus already warned
    const warn = BigInt(pot.escrow.intValue).subtract(pot.warned?.intValue ?? BigInt.zero);
    console.log(`orchidLock: escrow = ${pot.escrow.floatValue}, warned = ${pot.warned?.floatValue}, to warn = ${warn.toJSNumber()}`)

    return this.evalOrchidTx(
      this.lotteryContract.methods
        .edit(signer, adjust.toString(), warn.toString(), retrieve.toString())
        .send({
          from: funder,
          gas: OrchidContractV1.lottery_warn_max_gas
        }), OrchidTransactionType.Unlock
    );
  }

  // "Un-warn" (lock) the full warned (unlocked) amount.
  async orchidLock(pot: LotteryPot, funder: EthAddress, signer: EthAddress): Promise<string> {
    const adjust = BigInt.zero;
    const retrieve = BigInt.zero;
    // warn amount is negative the currently warned amount
    const warned = BigInt(pot.warned?.intValue ?? BigInt.zero);
    const warn: BigInt = warned.multiply(BigInt(-1));
    console.log(`orchidUnock: warn = ${warn}`)

    return this.evalOrchidTx(
      this.lotteryContract.methods
        .edit(signer, adjust.toString(), warn.toString(), retrieve.toString())
        .send({
          from: funder,
          gas: OrchidContractV1.lottery_lock_max_gas
        }), OrchidTransactionType.Lock
    );
  }

  /// Get the lottery pot balance and escrow amount for the specified address.
  async orchidGetLotteryPot(funder: Wallet, signer: Signer): Promise<LotteryPot> {
    // Allow overrides
    let overrideBalance: LotFunds | null = this.fundsTokenType.fromString(getParam("balance"));
    console.log("override balance = ", overrideBalance, getParam("balance"))
    let overrideDeposit: LotFunds | null = this.fundsTokenType.fromString(getParam("deposit"));
    //console.log("get lottery pot for signer: ", signer);
    // function read(IERC20 token, address funder, address signer) external view
    //   returns (uint256, uint256)
    let result = await this.lotteryContract.methods
      .read(EthereumAddress.zeroString, funder.address, signer.address,
      ).call({from: funder.address});
    if (result == null || result.length < 3) {
      console.log("get lottery pot failed");
      throw new Error("Unable to get lottery pot");
    }
    const escrow_amount = BigInt(result[0]);
    let mask128 = BigInt(2).pow(128).minus(1);
    const balance: LotFunds = overrideBalance || this.fundsTokenType.fromInt(escrow_amount.and(mask128));
    const deposit: LotFunds = overrideDeposit || this.fundsTokenType.fromInt(escrow_amount.shiftRight(BigInt(128)));
    // console.log(`getlotterypot: escrow_amount = ${escrow_amount}, balance=${balance.intValue}, deposit=${deposit.intValue}`)

    const unlock_warned = BigInt(result[1]);
    const unlock = unlock_warned.shiftRight(128);
    console.log(`getlotterypot: warned = ${unlock}`)
    const unlockDate: Date | null = unlock > 0 ? new Date(unlock * 1000) : null;
    const warned = this.fundsTokenType.fromInt(unlock_warned.and(mask128));

    console.log("Pot info: ", balance, "escrow: ", deposit, "unlock:", unlock, "warned: ", warned, "unlock date:", unlockDate);
    return new LotteryPot(signer, balance, deposit, unlockDate, warned);
  }

  // Exercise the reset account feature of the lotter_test_reset contract.
  async orchidReset(funder: Wallet): Promise<string> {
    throw Error("unimplemented")
    /*
    return this.evalOrchidTx(
      this.lottery.methods.reset(funder.address)
        .send({
          from: funder.address,
          gas: OrchidContractV1.lottery_move_max_gas,
        }), OrchidTransactionType.Reset
    );
    */
  }

  // The current median gas price for the past few blocks
  async getGasPrice(): Promise<GasFunds> {
    return OrchidEthereumApiV0Impl.getGasPrice(this.gasTokenType, this.web3);
  }

  getPricing(): Promise<Pricing> {
    console.log("TESTING: FAKE PRICING!")
    let pricing: Pricing = new Pricing(
      this.fundsTokenType,
      this.gasTokenType,
      1.0,
      1.0
    );
    return new Promise<Pricing>(async function (resolve, reject) {
      await new Promise(resolve => setTimeout(resolve, 300));
      resolve(pricing);
    });
  }

  get contractsOverridden(): boolean {
    return OrchidContractV1.contracts_overridden();
  }

  get requiredConfirmations(): number {
    if (this.chainInfo.isGanache) {
      return 1
    }
    return this.contractsOverridden ? 1 : 2
  };

  async getAccountCreationGasRequired(): Promise<GasFunds> {
    let gasPrice = await this.getGasPrice();
    return gasPrice.multiply(OrchidContractV1.add_funds_total_max_gas);
  };

  async getLotteryUpdateEvents(funder: EthAddress, signer: EthAddress): Promise<LotteryPotUpdateEvent[]> {

    let events = await this.lotteryContract.getPastEvents('Update', {
      filter: {funder: funder, signer: signer},
      fromBlock: OrchidContractV1.startBlock,
      toBlock: 'latest'
    });

    let txs: Transaction [] = await Promise.all(
      events.map(e => {
        return this.web3.eth.getTransaction(e.transactionHash)
      }));

    let items = txs.map(tx => {
      try {
        let input: any = abiDecoder.decodeMethod(tx.input);
        // console.log("input = ", input);

        if (input['name'] !== "move") {
          return null;
        }
        // todo: handle more complex move operations
        // The adjustments made between balance and escrow
        let adjust_retrieve = input['params'][1]['value']
        if (!BigInt(adjust_retrieve).isZero()) {
          return null;
        }
        if (!tx.blockNumber) {
          return null;
        }

        // The payable amount sent into the move operation
        let amount = this.fundsTokenType.fromIntString(tx.value);
        console.log("amount = ", amount);

        // todo: get the date from the block
        // let block = await this.web3.eth.getBlock(tx.blockNumber)
        let timestamp = new Date(0);

        return new LotteryPotUpdateEvent(
          null, amount, null, null,
          tx.blockNumber, timestamp, tx.gasPrice, tx.gas, tx.hash
        );
      } catch (err) {
        console.log("err parsing transaction = ", err);
        return null;
      }
    })
      .filter((e) => {
        return e !== null
      }) as LotteryPotUpdateEvent []

    return items;
  }

  get marketConditions(): MarketConditionsSource {
    return new MarketConditionsSourceImplV1(this) as MarketConditionsSource;
  }
   */
}
