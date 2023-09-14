import Web3 from "web3";
import {
  EthAddress,
  EthereumKey,
  LotteryPot,
  LotteryPotUpdateEvent,
  Signer,
  Wallet
} from "../orchid-eth-types";
import {GasFunds, LotFunds, min, TokenType} from "../orchid-eth-token-types";
import {debugV0, getParam} from "../../util/util";
import {OrchidAPI} from "../orchid-api";
import {OrchidTransaction, OrchidTransactionType} from "../orchid-tx";
import {PromiEvent} from "web3-core";
import {
  GasPricingStrategy,
  ORCHID_SIGNER_KEYS_WALLET,
  OrchidEthereumAPI,
  Web3Wallet
} from "../orchid-eth";
import {OrchidContractMainNetV0} from "./orchid-eth-contract-v0";
import {Contract} from "web3-eth-contract";
import {EtherscanIO} from "../etherscan-io";
import {EVMChains} from "../chains/chains";
import {MarketConditionsSource} from "../orchid-market-conditions";
import {MarketConditionsSourceImplV0} from "./orchid-eth-market-v0";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill
export type V1 = OrchidEthereumApiV0Impl

export class OrchidEthereumApiV0Impl implements OrchidEthereumAPI {

  public web3: Web3
  public chainId = debugV0() ? EVMChains.ganacheChain.chainId : EVMChains.ETHEREUM_MAIN_NET;
  public fundsTokenType: TokenType<LotFunds>
  public gasTokenType: TokenType<GasFunds>
  public isV0 = true

  tokenContract: Contract;
  lotteryContract: Contract;
  directoryContract: Contract;

  constructor(web3: Web3) {
    this.web3 = web3;
    this.fundsTokenType = EVMChains.OXT_TOKEN;
    this.gasTokenType = EVMChains.ETH_TOKEN;
    this.tokenContract = new web3.eth.Contract(OrchidContractMainNetV0.token_abi, OrchidContractMainNetV0.token_addr());
    this.lotteryContract = new web3.eth.Contract(OrchidContractMainNetV0.lottery_abi, OrchidContractMainNetV0.lottery_addr());
    this.directoryContract = new web3.eth.Contract(OrchidContractMainNetV0.directory_abi, OrchidContractMainNetV0.directory_addr());
  }

  /// Get the user's wallet funds and gas token funds balances.
  async orchidGetWallet(): Promise<Wallet> {
    const accounts = await this.web3.eth.getAccounts();
    if (accounts.length === 0) {
      throw Error("no accounts");
    }

    const wallet = new Wallet(this.fundsTokenType.zero, this.gasTokenType.zero);
    wallet.address = accounts[0];

    // gas funds
    try {
      let overrideGas: GasFunds | null = this.gasTokenType.fromString(getParam('walletGasFunds'))
      wallet.gasFundsBalance = (overrideGas || this.gasTokenType.fromIntString(await this.web3.eth.getBalance(accounts[0])));
    } catch (err) {
      console.log("Error getting gas funds balance", err);
      throw err;
    }

    // lottery funds
    try {
      let overrideBalance: LotFunds | null = this.fundsTokenType.fromString(getParam('walletFunds'))
      wallet.fundsBalance = (overrideBalance || this.fundsTokenType.fromInt(await this.tokenContract.methods.balanceOf(accounts[0]).call()));
    } catch (err) {
      console.log("Error getting funds balance", err);
      throw err;
    }
    return wallet;
  }

  async orchidGetSigners(wallet: Wallet): Promise<Signer []> {
    if (getParam("no_signers")) {
      return [];
    }
    let signerAddresses;
    try {
      signerAddresses = await this.lotteryContract.methods.keys(wallet.address).call();
    } catch (err) {
      console.log("Error getting signers list", err);
      throw err;
    }
    console.log("orchidGetSigners: orchid signers: ", signerAddresses);

    let signerKeys = this.orchidGetSignerKeys() as EthereumKey [];
    return OrchidEthereumApiV0Impl.addKeysToSigners(signerAddresses, signerKeys, wallet);
  }

  public static addKeysToSigners(
    signerAddresses: EthAddress [],
    signerKeys: EthereumKey [],
    wallet: Wallet
  ): Signer [] {
    // Add the signer keys for any signers created in this wallet.
    return signerAddresses.map((address: EthAddress) => {
      let found = Array.from(signerKeys).find(key => key.address === address);
      let secret = found === undefined ? undefined : found.privateKey;
      return new Signer(wallet, address, secret);
    });
  }

/// Get the Orchid signer keys wallet in local storage.
  orchidGetSignerKeys(): Web3Wallet {
    return OrchidEthereumApiV0Impl.orchidGetSignerKeys(this.web3);
  }

  static orchidGetSignerKeys(web3: Web3): Web3Wallet {
    return web3.eth.accounts.wallet.load("", ORCHID_SIGNER_KEYS_WALLET);
  }

  /// Create a new signer keypair and save it in the Orchid signer keys wallet in local storage.
  orchidCreateSigner(wallet: Wallet): Signer {
    return OrchidEthereumApiV0Impl.orchidCreateSigner(this.web3, wallet);
  }

  static orchidCreateSigner(web3: Web3, wallet: Wallet): Signer {
    let signersWallet = OrchidEthereumApiV0Impl.orchidGetSignerKeys(web3);
    let signerAccount = web3.eth.accounts.create();
    signersWallet.add(signerAccount);
    signersWallet.save("", ORCHID_SIGNER_KEYS_WALLET);
    return new Signer(wallet, signerAccount.address, signerAccount.privateKey);
  }

  /// Transfer the int amount from the user to the specified lottery pot address.
  /// If the total exceeds walletBalance the amount value is automatically reduced.
  async orchidAddFunds(
    funder: EthAddress, signer: EthAddress, amount: LotFunds, escrow: LotFunds, wallet: Wallet
  ): Promise<string> {
    //return fakeTx(false);

    // Choose a gas price
    let medianGasPrice: GasFunds = await this.getGasPrice();
    let gasPrice: number | undefined = GasPricingStrategy.chooseGasPrice(
      OrchidContractMainNetV0.add_funds_total_max_gas, medianGasPrice, wallet.gasFundsBalance);
    if (!gasPrice) {
      console.log("addfunds: gas price potentially too low.");
    }

    // Don't attempt to add more than the wallet balance.
    // This mitigates the potential for rounding errors in calculated amounts.
    const total: LotFunds = min(amount.add(escrow), wallet.fundsBalance);
    console.log("Add funds  signer: ", signer, " amount: ", (total.subtract(escrow)), " escrow: ", escrow);

    const thisCapture = this;

    async function doApproveTx() {
      return new Promise<string>(function (resolve, reject) {
        thisCapture.tokenContract.methods.approve(
          OrchidContractMainNetV0.lottery_addr(),
          total.intValue.toString()
        ).send({
          from: funder,
          gas: OrchidContractMainNetV0.token_approval_max_gas,
          gasPrice: gasPrice
        })
          // An approval tx resolves immediately after the user submits.
          .on("transactionHash", (hash: any) => {
            console.log("Approval hash: ", hash);
            resolve(hash);
          })
          .on('confirmation', (confirmationNumber: any, receipt: any) => {
            console.log("Approval confirmation ", confirmationNumber, JSON.stringify(receipt));
          })
          .on('error', (err: any) => {
            console.log("Approval error: ", JSON.stringify(err));
            // If there is an error in the approval assume Funding will fail.
            reject(err['message']);
          });
      });
    }

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

  /// Transfer the int amount from the user to the specified directory address.
  /// Amount won't exceed walletBalance.
  async orchidStakeFunds(
    funder: EthAddress, stakee: EthAddress, amount: LotFunds, wallet: Wallet, delay: BigInt
  ): Promise<string> {

    amount = min(amount, wallet.fundsBalance);
    const delay_value = BigInt(delay);
    console.log("Stake funds amount: ", amount);

    // Choose a gas price
    let medianGasPrice = await this.getGasPrice();
    let gasPrice = GasPricingStrategy.chooseGasPrice(
      OrchidContractMainNetV0.stake_funds_total_max_gas, medianGasPrice, wallet.gasFundsBalance);
    if (!gasPrice) {
      console.log("Add funds: gas price potentially too low.");
    }

    const thisCapture = this;

    async function doApproveTx() {
      return new Promise<string>(function (resolve, reject) {
        thisCapture.tokenContract.methods.approve(
          OrchidContractMainNetV0.directory_addr(),
          amount.intValue.toString()
        ).send({
          from: funder,
          gas: OrchidContractMainNetV0.token_approval_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash: any) => {
            console.log("Approval hash: ", hash);
            resolve(hash);
          })
          .on('confirmation', (confirmationNumber: any, receipt: any) => {
            console.log("Approval confirmation ", confirmationNumber, JSON.stringify(receipt));
          })
          .on('error', (err: any) => {
            console.log("Approval error: ", JSON.stringify(err));
            // If there is an error in the approval assume Funding will fail.
            reject(err['message']);
          });
      });
    }

    async function doFundTx(approvalHash: string) {
      return new Promise<string>(function (resolve, reject) {
        thisCapture.directoryContract.methods.push(
          stakee, amount.intValue.toString(), delay_value.toString()
        ).send({
          from: funder,
          gas: OrchidContractMainNetV0.directory_push_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash: any) => {
            console.log("Stake hash: ", hash);
            OrchidAPI.shared().transactionMonitor.add(
              new OrchidTransaction(new Date(), OrchidTransactionType.StakeFunds, thisCapture.chainId, [approvalHash, hash]));
          })
          .on('confirmation', (confirmationNumber: any, receipt: any) => {
            console.log("Stake confirmation", confirmationNumber, JSON.stringify(receipt));
            // Wait for confirmations on the funding tx.
            if (confirmationNumber >= thisCapture.requiredConfirmations) {
              const hash = receipt['transactionHash'];
              resolve(hash);
            } else {
              console.log("waiting for more confirmations...");
            }
          })
          .on('error', (err: any) => {
            console.log("Stake error: ", JSON.stringify(err));
            reject(err['message']);
          });
      });
    }

    // The approval tx resolves immediately after the user submits.
    
    let approvalHash = await doApproveTx();

    // Introduce a short artificial delay before issuing the second tx
    // Issue: We have had reports of problems where only one dialog is presented to the user.
    // Issue: Trying this to see if it mitigates any race conditions in the wallet.
    await new Promise(r => setTimeout(r, 1000));

    // The UI monitors the funding tx.
    return doFundTx(approvalHash);
  }

  async orchidGetStake(stakee: EthAddress): Promise<LotFunds> {
    console.log("orchid get stake");
    let stake = await this.directoryContract.methods.heft(stakee).call();
    return this.fundsTokenType.fromInt(stake) || this.fundsTokenType.zero
  }

  evalOrchidTx<T>(promise: PromiEvent<T>, type: OrchidTransactionType): Promise<string> {
    return OrchidEthereumApiV0Impl.evalOrchidTx(promise, type, this.chainId);
  }

  /// Evaluate an Orchid method call, returning the confirmation transaction has or error.
  static evalOrchidTx<T>(promise: PromiEvent<T>, type: OrchidTransactionType, chainId: number): Promise<string> {
    return new Promise<string>(function (resolve, reject) {
      promise
        .on("transactionHash", (hash) => {
          console.log("hash: ", hash);
          if (type) {
            OrchidAPI.shared().transactionMonitor.add(
              new OrchidTransaction(new Date(), type, chainId, [hash]));
          }
        })
        .on('confirmation', (confirmationNumber, receipt) => {
          console.log("confirmation", confirmationNumber, JSON.stringify(receipt));
          // Wait for one confirmation on the tx.
          const hash = receipt['transactionHash'];
          resolve(hash);
        })
        .on('error', (err) => {
          console.log("error: ", JSON.stringify(err));
          reject(err['message']);
        });
    });
  }

  /// Move `amount` from balance to escrow, not exceeding `potBalance`.
  async orchidMoveFundsToEscrow(
    funder: EthAddress, signer: EthAddress, amount: LotFunds, potBalance: LotFunds): Promise<string> {
    console.log(`moveFunds amount: ${amount.toString()}`);

    // Don't take more than the pot balance. This check mitigates rounding errors.
    amount = min(amount, potBalance);

    return this.evalOrchidTx(
      this.lotteryContract.methods.move(signer, amount.intValue.toString()).send({
        from: funder,
        gas: OrchidContractMainNetV0.lottery_move_max_gas,
      }), OrchidTransactionType.MoveFundsToEscrow
    );
  }

  /// Withdraw `amount` from the lottery pot to the specified eth address, not exceeding `potBalance`.
  async orchidWithdrawFunds(
    funder: EthAddress, signer: EthAddress, targetAddress: EthAddress, amount: LotFunds, potBalance: LotFunds
  ): Promise<string> {
    // pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow) external
    let autolock = true;
    let escrow = this.fundsTokenType.zero;

    // Don't take more than the pot balance. This check mitigates rounding errors.
    amount = min(amount, potBalance);
    console.log(`withdrawFunds to: ${targetAddress} amount: ${amount}`);

    return this.evalOrchidTx(
      this.lotteryContract.methods.pull(signer, targetAddress, autolock, amount.intValue.toString(), escrow.intValue.toString()).send({
        from: funder,
        gas: OrchidContractMainNetV0.lottery_pull_amount_max_gas,
      }), OrchidTransactionType.WithdrawFunds
    );
  }

  /// Pull all funds and escrow, subject to lock time.
  async orchidWithdrawFundsAndEscrow(pot: LotteryPot, targetAddress: EthAddress): Promise<string> {
    console.log("withdrawFundsAndEscrow");
    let autolock = true;
    const funder = pot.signer.wallet.address;
    const signer = pot.signer.address;
    return this.evalOrchidTx(
      this.lotteryContract.methods.yank(signer, targetAddress, autolock).send({
        from: funder,
        gas: OrchidContractMainNetV0.lottery_pull_all_max_gas
      }), OrchidTransactionType.WithdrawFunds
    );
  }

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

  /// Get the lottery pot balance and escrow amount for the specified address.
  async orchidGetLotteryPot(funder: Wallet, signer: Signer): Promise<LotteryPot> {
    // Allow overrides
    let overrideBalance: LotFunds | null = this.fundsTokenType.fromString(getParam("balance"));
    let overrideDeposit: LotFunds | null = this.fundsTokenType.fromString(getParam("deposit"));
    //console.log("get lottery pot for signer: ", signer);
    let result = await this.lotteryContract.methods
      .look(funder.address, signer.address)
      .call({from: funder.address});
    if (result == null || result.length < 3) {
      console.log("get lottery pot failed");
      throw new Error("Unable to get lottery pot");
    }
    const balance: LotFunds = overrideBalance || this.fundsTokenType.fromInt(result[0]);
    const escrow: LotFunds = overrideDeposit || this.fundsTokenType.fromInt(result[1]);
    const unlock: number = Number(result[2]);
    const unlockDate: Date | null = unlock > 0 ? new Date(unlock * 1000) : null;
    //console.log("Pot info: ", balance, "escrow: ", escrow, "unlock: ", unlock, "unlock date:", unlockDate);
    return LotteryPot.from(signer, balance, escrow, unlockDate);
  }

  // Exercise the reset account feature of the lotter_test_reset contract.
  async orchidReset(funder: Wallet): Promise<string> {
    return this.evalOrchidTx(
      this.lotteryContract.methods.reset(funder.address)
        .send({
          from: funder.address,
          gas: OrchidContractMainNetV0.lottery_move_max_gas,
        }), OrchidTransactionType.Reset
    );
  }

  // The current median gas price for the past few blocks
  async getGasPrice(): Promise<GasFunds> {
    return OrchidEthereumApiV0Impl.getGasPrice(this.gasTokenType, this.web3);
  }

  static async getGasPrice(gasTokenType: TokenType<GasFunds>, web3: Web3): Promise<GasFunds> {
    try {
      let gasPrice = gasTokenType.fromIntString(await web3.eth.getGasPrice());
      // console.log("gasPrice = ", gasPrice.floatValue)
      return gasPrice
    } catch (err) {
      console.log("WARNING: defaulting gas price in disconnected state.  Testing only!")
      let GWEI = 1e9;
      return gasTokenType.fromNumber(50 / GWEI);
    }
  }

  get contractsOverridden(): boolean {
    return OrchidContractMainNetV0.contracts_overridden();
  }

  get requiredConfirmations(): number {
    return this.contractsOverridden ? 1 : 2
  };

  async getAccountCreationGasRequired(): Promise<GasFunds> {
    let gasPrice = await this.getGasPrice();
    return gasPrice.multiply(OrchidContractMainNetV0.add_funds_total_max_gas);
  };

  async getLotteryUpdateEvents(funder: EthAddress, signer: EthAddress): Promise<LotteryPotUpdateEvent[]> {
    return await new EtherscanIO().getLotteryUpdateEvents(
      OrchidContractMainNetV0.lottery_addr(),
      OrchidContractMainNetV0.lottery_update_event_hash,
      OrchidContractMainNetV0.startBlock,
      funder, signer, this.fundsTokenType
    );
  }

  get marketConditions(): MarketConditionsSource {
    return new MarketConditionsSourceImplV0(this) as MarketConditionsSource;
  }
}
