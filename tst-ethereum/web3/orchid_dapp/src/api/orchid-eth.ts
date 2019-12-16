//
// Orchid Ethereum Contracts Lib
//
import {OrchidContracts} from "./orchid-eth-contracts";
import {Address} from "./orchid-types";
import Web3 from "web3";
import PromiEvent from "web3/promiEvent";
import {WalletStatus} from "./orchid-api";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

declare global {
  interface Window {
    ethereum: any
  }
}
let web3: Web3;

/// A Funder address containing ETH to perform contract transactions  and possibly
/// OXT to fund a Lottery Pot.
export class Wallet {
  public address: Address;
  public ethBalance: BigInt; // Wei
  public oxtBalance: BigInt; // Oxt-Wei

  constructor() {
    this.address = "";
    this.ethBalance = BigInt(0);
    this.oxtBalance = BigInt(0);
  }
}

/// A Wallet may have many signers, each of which is essentially an "Orchid Account",
// controlling a Lottery Pot.
export class Signer {
  public wallet: Wallet;
  public address: Address;

  constructor(wallet: Wallet, address: Address) {
    this.wallet = wallet;
    this.address = address;
  }
}

/// A Lottery Pot containing OXT funds against which lottery tickets are issued.
export class LotteryPot {
  public signer: Signer;
  public balance: BigInt; // Wei
  public escrow: BigInt; // Oxt-Wei
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

// Init the Web3 environment and the Orchid contracts
export function orchidInitEthereum(providerUpdateCallback?: (props: any) => void): Promise<WalletStatus> {
  console.log("init ethereum");
  return new Promise(function (resolve, reject) {
    /*window.addEventListener('load',*/
    (async () => {
      if (window.ethereum) {
        console.log("Modern dapp browser.");
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
      }

      let networkNumber = await web3.eth.net.getId();
      console.log("network number: ", networkNumber);
      if (networkNumber !== 1) {
        resolve(WalletStatus.WrongNetwork);
      }

      providerUpdateCallback && web3.currentProvider && (web3.currentProvider as any).publicConfigStore &&
      (web3.currentProvider as any).publicConfigStore.on('update', (props: any) => {
        providerUpdateCallback && providerUpdateCallback(props);
      });

      try {
        OrchidContracts.token = new web3.eth.Contract(OrchidContracts.token_abi, OrchidContracts.token_addr);
        OrchidContracts.lottery = new web3.eth.Contract(OrchidContracts.lottery_abi, OrchidContracts.lottery_addr());
      } catch (err) {
        console.log("Error constructing contracts");
        resolve(WalletStatus.Error);
      }

      resolve(WalletStatus.Connected);
    })();
  });
}

/// Get the user's ETH wallet balance and OXT-wei token balance (1e18 parts OXT).
export async function orchidGetWallet(): Promise<Wallet> {
  console.log("orchid get wallet");
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

export async function orchidGetSigners(wallet: Wallet): Promise<Signer []> {
  let keys;
  try {
    keys = await OrchidContracts.lottery.methods.keys(wallet.address).call();
  } catch (err) {
    console.log("Error getting signers list", err);
    throw err;
  }
  console.log("orchid signers: ", keys);
  return keys.map((key: Address) => new Signer(wallet, key));
}

/// Transfer the amount in OXT-wei from the user to the specified lottery pot address.
export async function orchidAddFunds(funder: Address, signer: Address, amount: BigInt, escrow: BigInt): Promise<string> {
  // return fakeTx(false);
  console.log("Add funds  signer: ", signer, " amount: ", amount, " escrow: ", escrow);
  const amount_value = BigInt(amount); // Force our polyfill BigInt?
  const escrow_value = BigInt(escrow);
  const total = amount_value + escrow_value;

  async function doApproveTx() {
    return new Promise<string>(function (resolve, reject) {
      OrchidContracts.token.methods.approve(
        OrchidContracts.lottery_addr(),
        total.toString()
      ).send({
        from: funder,
        gas: OrchidContracts.token_approval_max_gas,
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

  async function doFundTx() {
    console.log("do fund tx");
    return new Promise<string>(function (resolve, reject) {
      OrchidContracts.lottery.methods.push(
        signer,
        total.toString(),
        escrow_value.toString()
      ).send({
        from: funder,
        gas: OrchidContracts.lottery_push_max_gas,
      })
        .on("transactionHash", (hash) => {
          console.log("Fund hash: ", hash);
        })
        .on('confirmation', (confirmationNumber, receipt) => {
          console.log("Fund confirmation", confirmationNumber, JSON.stringify(receipt));
          // Wait for confirmations on the funding tx.
          const requiredConfirmations = 2;
          if (confirmationNumber >= requiredConfirmations) {
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
  await doApproveTx();
  // The UI monitors the funding tx.
  return doFundTx();
}

/// Evaluate an Orchid method call, returning the confirmation transaction has or error.
function evalOrchidTx<T>(promise: PromiEvent<T>): Promise<string> {
  return new Promise<string>(function (resolve, reject) {
    promise
      .on("transactionHash", (hash) => {
        console.log("hash: ", hash);
      })
      .on('confirmation', (confirmationNumber, receipt) => {
        console.log("confirmation", confirmationNumber, JSON.stringify(receipt));
        // Wait for one confirmation on the tx.
        const hash = receipt['transactionHash'];
        resolve(hash);
      })
      .on('error', (err) => {
        console.log("error: ", JSON.stringify(err));
        reject(err);
      });
  });
}

export async function orchidMoveFundsToEscrow(funder: Address, signer: Address, amount: BigInt): Promise<string> {
  console.log(`moveFunds amount: ${amount.toString()}`);
  return evalOrchidTx(
    OrchidContracts.lottery.methods.move(signer, amount.toString()).send({
      from: funder,
      gas: OrchidContracts.lottery_move_max_gas,
    })
  );
}

export async function orchidWithdrawFunds(funder: Address, signer: Address, targetAddress: Address, amount: BigInt): Promise<string> {
  console.log(`withdrawFunds to: ${targetAddress} amount: ${amount}`);
  // pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow) external {
  let autolock = true;
  let escrow = BigInt(0);
  return evalOrchidTx(
    OrchidContracts.lottery.methods.pull(signer, targetAddress, autolock, amount.toString(), escrow.toString()).send({
      from: funder,
      gas: OrchidContracts.lottery_pull_amount_max_gas,
    })
  );
}

/// Pull all funds and escrow, subject to lock time.
export async function orchidWithdrawFundsAndEscrow(funder: Address, signer: Address, targetAddress: Address): Promise<string> {
  console.log("withdrawFundsAndEscrow");
  let autolock = true;
  return evalOrchidTx(
    OrchidContracts.lottery.methods.yank(signer, targetAddress, autolock).send({
      from: funder,
      gas: OrchidContracts.lottery_pull_all_max_gas
    })
  );
}

/// Clear the unlock / warn time period.
export async function orchidLock(funder: Address, signer: Address): Promise<string> {
  return evalOrchidTx(
    OrchidContracts.lottery.methods.lock(signer).send({
      from: funder,
      gas: OrchidContracts.lottery_lock_max_gas
    })
  );
}

/// Start the unlock / warn time period (one day in the future).
export async function orchidUnlock(funder: Address, signer: Address): Promise<string> {
  return evalOrchidTx(
    OrchidContracts.lottery.methods.warn(signer).send({
      from: funder,
      gas: OrchidContracts.lottery_warn_max_gas
    })
  );
}

/// Get the lottery pot balance and escrow amount for the specified address.
export async function orchidGetLotteryPot(funder: Wallet, signer: Signer): Promise<LotteryPot> {
  console.log("get lottery pot for signer: ", signer);
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

export function isEthAddress(str: string): boolean {
  return web3.utils.isAddress(str);
}

// Convert a wei value (string or number) to an OXT String rounded to the specified
// number of decimal places.
export function weiToOxtString(wei: BigInt, decimals: number) {
  decimals = Math.round(decimals);
  let val = parseFloat(web3.utils.fromWei(wei.toString()));
  return val.toFixed(decimals).toString();
}

export function oxtToWei(oxt: number): BigInt {
  return BigInt(oxt * 1e18);
}

export function oxtToWeiString(oxt: number): string {
  return oxtToWei(oxt).toString();
}

// TEST UI ONLY:
/*
async function fakeTx(fail: boolean): Promise<string> {
  return new Promise<string>(async function (resolve, reject) {
    await new Promise(resolve => setTimeout(resolve, 1000));
    if (fail) {
      reject("tx error");
    } else {
      resolve('0x12341234123412341234123');
    }
  });
}
 */
