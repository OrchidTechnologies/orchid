//
// Orchid Ethereum Contracts Lib
//
import {OrchidContracts} from "./orchid-eth-contracts";
import {Address, Secret} from "./orchid-types";
import Web3 from "web3";
import PromiEvent from "web3/promiEvent";
import {OrchidAPI, WalletStatus} from "./orchid-api";
import {EthereumTransaction, OrchidTransaction, OrchidTransactionType} from "./orchid-tx";
import "../i18n/i18n_util";
import {getParam, removeHexPrefix} from "../util/util";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill
const ORCHID_SIGNER_KEYS_WALLET = "orchid-signer-keys";

declare global {
  interface Window {
    ethereum: any
  }
}
export let web3: Web3;
let web3ProviderListener: any;

/// A Funder address containing ETH to perform contract transactions  and possibly
/// OXT to fund a Lottery Pot.
export class Wallet {
  public address: Address;
  public ethBalance: BigInt; // Wei
  public oxtBalance: BigInt; // Keiki (1e18 per OXT)

  constructor() {
    this.address = "";
    this.ethBalance = BigInt(0);
    this.oxtBalance = BigInt(0);
  }
}

/// A Wallet may have many signers, each of which is essentially an "Orchid Account",
// controlling a Lottery Pot.
export class Signer {
  // The wallet with which this signer is associated.
  public wallet: Wallet;
  // The signer public address.
  public address: Address;
  // The signer private key, if available.
  public secret: Secret | undefined;

  constructor(wallet: Wallet, address: Address, secret?: Secret) {
    this.wallet = wallet;
    this.address = address;
    this.secret = removeHexPrefix(secret);
  }

  toConfigString(): string | undefined {
    if (this.secret === undefined) {
      return undefined;
    }
    return `account={protocol:"orchid",funder:"${this.wallet.address}",secret:"${this.secret}"}`;
  }
}

interface EthereumKey {
  address: string
  privateKey: string
}

export type Web3Wallet = any;

/// A Lottery Pot containing OXT funds against which lottery tickets are issued.
export class LotteryPot {
  public signer: Signer;
  public balance: BigInt; // Keiki
  public escrow: BigInt; // Keiki
  public unlock: Date | null;

  constructor(signer: Signer, balance: BigInt, escrow: BigInt, unlock: Date | null) {
    this.signer = signer;
    this.signer = signer;
    this.balance = balance;
    this.escrow = escrow;
    this.unlock = unlock;
  }

  isLocked(): boolean {
    return this.unlock == null || new Date() < this.unlock;
  }

  isUnlocked(): boolean {
    return !this.isLocked();
  }

  isUnlocking(): boolean {
    return this.unlock != null && new Date() < this.unlock;
  }
}

export class OrchidEthereumAPI {

  /// Init the Web3 environment and the Orchid contracts
  orchidInitEthereum(providerUpdateCallback?: (props: any) => void): Promise<WalletStatus> {
    return new Promise(function (resolve, reject) {
      (async () => {
        if (window.ethereum) {
          window.ethereum.autoRefreshOnNetworkChange = false;
          web3 = new Web3(window.ethereum);
          try {
            await window.ethereum.enable();
          } catch (error) {
            resolve(WalletStatus.NotConnected);
            console.log("User denied account access...");
          }
        } else if (web3) {
          console.log("Legacy dapp browser.");
          web3 = new Web3(web3.currentProvider);
        } else {
          console.log('Non-Ethereum browser.');
          resolve(WalletStatus.NoWallet);
          return;
        }

        let networkNumber = await web3.eth.net.getId();
        console.log("network number: ", networkNumber);
        if (networkNumber !== 1) {
          resolve(WalletStatus.WrongNetwork);
        }

        // Subscribe to provider account changes
        if (providerUpdateCallback && web3.currentProvider && (web3.currentProvider as any).publicConfigStore) {
          // Note: The provider update callback should only be passed once, but to be safe.
          if (web3ProviderListener) {
            try {
              web3ProviderListener.unsubscribe();
              console.log("existing provider listener successfully unsubscribed");
            } catch (err) {
              console.log("failed to unsubscribe existing provider listener");
            }
          }
          web3ProviderListener = (web3.currentProvider as any).publicConfigStore.on('update', (props: any) => {
            providerUpdateCallback && providerUpdateCallback(props);
          });
        }

        try {
          OrchidContracts.token = new web3.eth.Contract(OrchidContracts.token_abi, OrchidContracts.token_addr());
          OrchidContracts.lottery = new web3.eth.Contract(OrchidContracts.lottery_abi, OrchidContracts.lottery_addr());
          OrchidContracts.directory = new web3.eth.Contract(OrchidContracts.directory_abi, OrchidContracts.directory_addr());
        } catch (err) {
          console.log("Error constructing contracts");
          resolve(WalletStatus.Error);
        }

        (window as any).web3 = web3; // replace any injected version
        resolve(WalletStatus.Connected);
      })();
    });
  }

  /// Get the user's ETH wallet balance and Keiki token balance (1e18 per OXT).
  async orchidGetWallet(): Promise<Wallet> {
    const accounts = await web3.eth.getAccounts();
    const wallet = new Wallet();
    wallet.address = accounts[0];
    try {
      wallet.ethBalance = BigInt(await web3.eth.getBalance(accounts[0]));
    } catch (err) {
      console.log("Error getting eth balance", err);
      throw err;
    }
    try {
      wallet.oxtBalance = BigInt(await OrchidContracts.token.methods.balanceOf(accounts[0]).call());
    } catch (err) {
      console.log("Error getting oxt balance", err);
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
      signerAddresses = await OrchidContracts.lottery.methods.keys(wallet.address).call();
    } catch (err) {
      console.log("Error getting signers list", err);
      throw err;
    }
    console.log("orchidGetSigners: orchid signers: ", signerAddresses);

    // Add the signer keys for any signers created in this wallet.
    let signerKeys = this.orchidGetSignerKeys() as EthereumKey [];
    return signerAddresses.map((address: Address) => {
      let found = Array.from(signerKeys).find(key => key.address === address);
      let secret = found === undefined ? undefined : found.privateKey;
      return new Signer(wallet, address, secret);
    });
  }

  /// Get the Orchid signer keys wallet in local storage.
  orchidGetSignerKeys(): Web3Wallet {
    let keys = web3.eth.accounts.wallet.load("", ORCHID_SIGNER_KEYS_WALLET);
    return keys;
  }

  /// Create a new signer keypair and save it in the Orchid signer keys wallet in local storage.
  orchidCreateSigner(wallet: Wallet): Signer {
    let signersWallet = this.orchidGetSignerKeys();
    let signerAccount = web3.eth.accounts.create();
    signersWallet.add(signerAccount);
    signersWallet.save("", ORCHID_SIGNER_KEYS_WALLET);
    return new Signer(wallet, signerAccount.address, signerAccount.privateKey);
  }

  /// Transfer the amount in Keiki (1e18 per OXT) from the user to the specified lottery pot address.
  async orchidAddFunds(
    funder: Address, signer: Address, amount: BigInt, escrow: BigInt, gasPrice?: number
  ): Promise<string> {
    console.log("Add funds  signer: ", signer, " amount: ", amount, " escrow: ", escrow);
    //return fakeTx(false);
    const amount_value = BigInt(amount); // Force our polyfill BigInt?
    const escrow_value = BigInt(escrow);
    const total = amount_value.add(escrow_value);

    async function doApproveTx() {
      return new Promise<string>(function (resolve, reject) {
        OrchidContracts.token.methods.approve(
          OrchidContracts.lottery_addr(),
          total.toString()
        ).send({
          from: funder,
          gas: OrchidContracts.token_approval_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash) => {
            console.log("Approval hash: ", hash);
            resolve(hash);
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            console.log("Approval confirmation ", confirmationNumber, JSON.stringify(receipt));
          })
          .on('error', (err) => {
            console.log("Approval error: ", JSON.stringify(err));
            // If there is an error in the approval assume Funding will fail.
            reject(err['message']);
          });
      });
    }

    async function doFundTx(approvalHash: string) {
      return new Promise<string>(function (resolve, reject) {
        OrchidContracts.lottery.methods.push(
          signer,
          total.toString(),
          escrow_value.toString()
        ).send({
          from: funder,
          gas: OrchidContracts.lottery_push_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash) => {
            console.log("Fund hash: ", hash);
            OrchidAPI.shared().transactionMonitor.add(
              new OrchidTransaction(new Date(), OrchidTransactionType.AddFunds, [approvalHash, hash]));
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            console.log("Fund confirmation", confirmationNumber, JSON.stringify(receipt));
            // Wait for confirmations on the funding tx.
            if (confirmationNumber >= EthereumTransaction.requiredConfirmations) {
              const hash = receipt['transactionHash'];
              resolve(hash);
            } else {
              console.log("waiting for more confirmations...");
            }
          })
          .on('error', (err) => {
            console.log("Fund error: ", JSON.stringify(err));
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

  /// Transfer the amount in Keiki (1e18 per OXT) from the user to the specified directory address.
  async orchidStakeFunds(
    funder: Address, stakee: Address, amount: BigInt, delay: BigInt, gasPrice?: number
  ): Promise<string> {
    console.log("Stake funds amount: ", amount);
    const amount_value = BigInt(amount); // Force our polyfill BigInt?
    const delay_value = BigInt(delay);

    async function doApproveTx() {
      return new Promise<string>(function (resolve, reject) {
        OrchidContracts.token.methods.approve(
          OrchidContracts.directory_addr(),
          amount_value.toString()
        ).send({
          from: funder,
          gas: OrchidContracts.token_approval_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash) => {
            console.log("Approval hash: ", hash);
            resolve(hash);
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            console.log("Approval confirmation ", confirmationNumber, JSON.stringify(receipt));
          })
          .on('error', (err) => {
            console.log("Approval error: ", JSON.stringify(err));
            // If there is an error in the approval assume Funding will fail.
            reject(err['message']);
          });
      });
    }

    async function doFundTx(approvalHash: string) {
      return new Promise<string>(function (resolve, reject) {
        OrchidContracts.directory.methods.push(
          stakee, amount_value.toString(), delay_value.toString()
        ).send({
          from: funder,
          gas: OrchidContracts.directory_push_max_gas,
          gasPrice: gasPrice
        })
          .on("transactionHash", (hash) => {
            console.log("Stake hash: ", hash);
            OrchidAPI.shared().transactionMonitor.add(
              new OrchidTransaction(new Date(), OrchidTransactionType.StakeFunds, [approvalHash, hash]));
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            console.log("Stake confirmation", confirmationNumber, JSON.stringify(receipt));
            // Wait for confirmations on the funding tx.
            if (confirmationNumber >= EthereumTransaction.requiredConfirmations) {
              const hash = receipt['transactionHash'];
              resolve(hash);
            } else {
              console.log("waiting for more confirmations...");
            }
          })
          .on('error', (err) => {
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

  async orchidGetStake(stakee: Address): Promise<BigInt> {
    console.log("orchid get stake");
    let stake = await OrchidContracts.directory.methods.heft(stakee).call();
    return stake || BigInt(0);
  }

  /// Evaluate an Orchid method call, returning the confirmation transaction has or error.
  private evalOrchidTx<T>(promise: PromiEvent<T>, type: OrchidTransactionType): Promise<string> {
    return new Promise<string>(function (resolve, reject) {
      promise
        .on("transactionHash", (hash) => {
          console.log("hash: ", hash);
          if (type) {
            OrchidAPI.shared().transactionMonitor.add(
              new OrchidTransaction(new Date(), type, [hash]));
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

  async orchidMoveFundsToEscrow(funder: Address, signer: Address, amount: BigInt): Promise<string> {
    console.log(`moveFunds amount: ${amount.toString()}`);
    return this.evalOrchidTx(
      OrchidContracts.lottery.methods.move(signer, amount.toString()).send({
        from: funder,
        gas: OrchidContracts.lottery_move_max_gas,
      }), OrchidTransactionType.MoveFundsToEscrow
    );
  }

  async orchidWithdrawFunds(funder: Address, signer: Address, targetAddress: Address, amount: BigInt): Promise<string> {
    console.log(`withdrawFunds to: ${targetAddress} amount: ${amount}`);
    // pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow) external {
    let autolock = true;
    let escrow = BigInt(0);
    return this.evalOrchidTx(
      OrchidContracts.lottery.methods.pull(signer, targetAddress, autolock, amount.toString(), escrow.toString()).send({
        from: funder,
        gas: OrchidContracts.lottery_pull_amount_max_gas,
      }), OrchidTransactionType.WithdrawFunds
    );
  }

  /// Pull all funds and escrow, subject to lock time.
  async orchidWithdrawFundsAndEscrow(funder: Address, signer: Address, targetAddress: Address): Promise<string> {
    console.log("withdrawFundsAndEscrow");
    let autolock = true;
    return this.evalOrchidTx(
      OrchidContracts.lottery.methods.yank(signer, targetAddress, autolock).send({
        from: funder,
        gas: OrchidContracts.lottery_pull_all_max_gas
      }), OrchidTransactionType.WithdrawFunds
    );
  }

  /// Clear the unlock / warn time period.
  async orchidLock(funder: Address, signer: Address): Promise<string> {
    return this.evalOrchidTx(
      OrchidContracts.lottery.methods.lock(signer).send({
        from: funder,
        gas: OrchidContracts.lottery_lock_max_gas
      }), OrchidTransactionType.Lock
    );
  }

  /// Start the unlock / warn time period (one day in the future).
  async orchidUnlock(funder: Address, signer: Address): Promise<string> {
    return this.evalOrchidTx(
      OrchidContracts.lottery.methods.warn(signer).send({
        from: funder,
        gas: OrchidContracts.lottery_warn_max_gas
      }), OrchidTransactionType.Unlock
    );
  }

  /// Get the lottery pot balance and escrow amount for the specified address.
  async orchidGetLotteryPot(funder: Wallet, signer: Signer): Promise<LotteryPot> {
    //console.log("get lottery pot for signer: ", signer);
    let result = await OrchidContracts.lottery.methods
      .look(funder.address, signer.address)
      .call({from: funder.address});
    if (result == null || result._length < 3) {
      console.log("get lottery pot failed");
      throw new Error("Unable to get lottery pot");
    }
    const balance: BigInt = result[0];
    const escrow: BigInt = result[1];
    const unlock: number = Number(result[2]);
    const unlockDate: Date | null = unlock > 0 ? new Date(unlock * 1000) : null;
    console.log("Pot info: ", balance, "escrow: ", escrow, "unlock: ", unlock, "unlock date:", unlockDate);
    return new LotteryPot(signer, balance, escrow, unlockDate);
  }

  // Exercise the reset account feature of the lotter_test_reset contract.
  async orchidReset(funder: Wallet): Promise<string> {
    return this.evalOrchidTx(
      OrchidContracts.lottery.methods.reset(funder.address)
        .send({
          from: funder.address,
          gas: OrchidContracts.lottery_move_max_gas,
        }), OrchidTransactionType.Reset
    );
  }

  // The current median gas price for the past few blocks
  async medianGasPrice(): Promise<number> {
    return await web3.eth.getGasPrice()
  }
}

export class GasPricingStrategy {

  /// Choose a gas price taking into account current gas price and the wallet balance.
  /// This strategy uses a multiple of the current median gas price up to a hard limit on
  /// both gas price and fraction of the wallet's remaiing ETH balance.
  // Note: Some of the usage of BigInt in here is convoluted due to the need to import the polyfill.
  static chooseGasPrice(
    targetGasAmount: number, currentMedianGasPrice: number, currentEthBalance: BigInt): number | undefined {
    let maxPriceGwei = 21.0;
    let minPriceGwei = 2.0;
    let medianMultiplier = 2.0;
    let maxWalletFrac = 0.9;

    // Target our multiple of the median price
    let targetPrice: BigInt = BigInt(currentMedianGasPrice).multiply(medianMultiplier);

    // Don't exceed max price
    let maxPrice: BigInt = BigInt(maxPriceGwei).multiply(1e9);
    if (maxPrice < targetPrice) {
      console.log("Gas price calculation: limited by max price to : ", maxPriceGwei)
    }
    targetPrice = BigInt.min(targetPrice, maxPrice);

    // Don't fall below min price
    let minPrice: BigInt = BigInt(minPriceGwei).multiply(1e9);
    if (minPrice > targetPrice) {
      console.log("Gas price calculation: limited by min price to : ", minPriceGwei)
    }
    targetPrice = BigInt.max(targetPrice, minPrice);

    // Don't exceed max wallet fraction
    let targetSpend: BigInt = BigInt(targetPrice).multiply(targetGasAmount);
    let maxSpend = BigInt(Math.floor(BigInt(currentEthBalance) * maxWalletFrac));
    if (targetSpend > maxSpend) {
      console.log("Gas price calculation: limited by wallet balance: ", currentEthBalance)
    }
    targetSpend = BigInt.min(targetSpend, maxSpend);

    // Recalculate the price
    let price = BigInt(targetSpend).divide(targetGasAmount);

    console.log(`Gas price calculation, `
      + `targetGasAmount: ${targetGasAmount}, medianGasPrice: ${currentMedianGasPrice}, ethBalance: ${currentEthBalance}, chose price: ${BigInt(price).divide(1e9)}`
    );

    return price.toJSNumber();
  }
}

export function isEthAddress(str: string): boolean {
  return web3.utils.isAddress(str);
}

/// Convert a keiki value to an OXT String rounded to the specified
/// number of decimal places.
export function keikiToOxtString(keiki: BigInt, decimals: number) {
  decimals = Math.round(decimals);
  let val: number = keikiToOxt(keiki);
  return val.toFixedLocalized(decimals);
}

/// Convert keiki to an (approximate) OXT float value
export function keikiToOxt(keiki: BigInt): number {
  return parseFloat(web3.utils.fromWei(keiki.toString()));
}

export function oxtToKeiki(oxt: number): BigInt {
  return BigInt(oxt * 1e18);
}

export function oxtToKeikiString(oxt: number): string {
  return oxtToKeiki(oxt).toString();
}

