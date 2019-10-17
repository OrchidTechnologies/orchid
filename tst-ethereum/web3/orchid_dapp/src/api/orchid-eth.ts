//
// Orchid Ethereum Contracts Lib
//
import {OrchidContracts} from "./orchid-eth-contracts";
import {Address} from "./orchid-types";
import Web3 from "web3";
import PromiEvent from "web3/promiEvent";
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

declare global {
  interface Window {
    ethereum: any
  }
}
let web3: Web3;

export class Account {
  public address: Address;
  public ethBalance: BigInt; // Wei
  public oxtBalance: BigInt; // Oxt-Wei

  constructor() {
    this.address = "";
    this.ethBalance = BigInt(0);
    this.oxtBalance = BigInt(0);
  }
}

export class LotteryPot {
  public balance: BigInt; // Wei
  public escrow: BigInt; // Oxt-Wei
  public unlock: Date | null;

  constructor(balance: BigInt, escrow: BigInt, unlock: Date | null) {
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
export function orchidInitEthereum() {
  console.log("init ethereum");
  return new Promise(function (resolve, reject) {
    window.addEventListener('load', async () => {
      console.log("init ethereum on load running");
      // Modern DAPP browsers.
      if (window.ethereum) {
        window.ethereum.autoRefreshOnNetworkChange = false;
        console.log("Modern dapp browser.");
        web3 = new Web3(window.ethereum);
        try {
          await window.ethereum.enable();
        } catch (error) {
          console.log("User denied account access...");
        }
      }
      // Legacy DAPP browsers.
      else if (web3) {
        web3 = new Web3(web3.currentProvider);
      }
      // Non-dapp browsers...
      else {
        console.log('Non-Ethereum browser.');
        reject();
      }

      try {
        OrchidContracts.token = new web3.eth.Contract(OrchidContracts.token_abi, OrchidContracts.token_addr);
        OrchidContracts.lottery = new web3.eth.Contract(OrchidContracts.lottery_abi, OrchidContracts.lottery_addr);
      } catch (err) {
        console.log("Error constructing contracts");
      }

      resolve();
    });
  });
}

/// Get the user's ETH wallet balance and OXT-wei token balance (1e18 parts OXT).
export async function orchidGetAccount() {
  const accounts = await web3.eth.getAccounts();
  const account = new Account();
  account.address = accounts[0];
  try {
    account.ethBalance = BigInt(await web3.eth.getBalance(accounts[0]));
  } catch (err) {
    console.log("Error getting eth balance", err);
  }
  try {
    account.oxtBalance = BigInt(await OrchidContracts.token.methods.balanceOf(accounts[0]).call());
  } catch (err) {
    console.log("Error getting oxt balance", err);
  }
  return account;
}

// TODO: BigInt
/// Transfer the amount in OXT-wei string value from the user to the specified lottery pot address.
export async function orchidAddFunds(addr: Address, amount: string, escrow: string): Promise<string> {
  // return fakeTx(false);
  console.log("Add funds - address: ", addr, " amount: ", amount, " escrow: ", escrow);
  const accounts = await web3.eth.getAccounts();
  const amount_value = BigInt(amount);
  const escrow_value = BigInt(escrow);
  const total = amount_value + escrow_value;

  // Perform the approve and fund transactions with some sequencing within a single promise.
  return new Promise<string>(function (resolve, reject) {

    function doApproveTx(onComplete: () => void): void {
      OrchidContracts.token.methods.approve(OrchidContracts.lottery_addr, total.toString()).send({
        from: accounts[0],
        gas: OrchidContracts.token_approval_max_gas,
      })
          .on("transactionHash", (hash) => {
            console.log("Approval hash: ", hash);
            onComplete()
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            console.log("Approval confirmation ", confirmationNumber, JSON.stringify(receipt));
          })
          .on('error', (err) => {
            console.log("Approval error: ", JSON.stringify(err));
            // If there is an error in the approval assume Funding will fail.
            reject(err);
          });
    }

    function doFundTx(): void {
      OrchidContracts.lottery.methods.push(amount_value.toString(), total.toString()).send({
        from: accounts[0],
        gas: OrchidContracts.lottery_push_max_gas,
      })
          .on("transactionHash", (hash) => {
            console.log("Fund hash: ", hash);
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            console.log("Fund confirmation", confirmationNumber, JSON.stringify(receipt));
            // Wait for one confirmation on the funding tx.
            const hash = receipt['transactionHash'];
            resolve(hash);
          })
          .on('error', (err) => {
            console.log("Fund error: ", JSON.stringify(err));
            reject(err);
          });
    }

    try {
      return doApproveTx(doFundTx);
    } catch (err) {
      console.log("error:", JSON.stringify(err));
      reject("error: " + err);
    }
  });
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

// TODO: BigInt
export async function orchidMoveFundsToEscrow(amount: string): Promise<string> {
  console.log(`moveFunds amount: ${amount}`);
  const accounts = await web3.eth.getAccounts();
  return evalOrchidTx(
      OrchidContracts.lottery.methods.move(amount).send({
        from: accounts[0],
        gas: OrchidContracts.lottery_move_max_gas,
      })
  );
}

// TODO: BigInt
export async function orchidWithdrawFunds(sendTo: Address, amount: string): Promise<string> {
  console.log(`withdrawFunds to: ${sendTo} amount: ${amount}`);
  const accounts = await web3.eth.getAccounts();
  return evalOrchidTx(
      OrchidContracts.lottery.methods.pull(sendTo, amount).send({
        from: accounts[0],
        gas: OrchidContracts.lottery_pull_amount_max_gas,
      })
  );
}

/// Pull all funds and escrow, subjet to lock time.
export async function orchidWithdrawFundsAndEscrow(sendTo: Address): Promise<string> {
  console.log("withdrawFundsAndEscrow");
  const accounts = await web3.eth.getAccounts();
  return evalOrchidTx(
      OrchidContracts.lottery.methods.pull(sendTo).send({
        from: accounts[0],
        gas: OrchidContracts.lottery_pull_all_max_gas
      })
  );
}

/// Clear the unlock / warn time period.
export async function orchidLock(): Promise<string> {
  const accounts = await web3.eth.getAccounts();
  return evalOrchidTx(
      OrchidContracts.lottery.methods.lock().send({
        from: accounts[0],
        gas: OrchidContracts.lottery_lock_max_gas
      })
  );
}

/// Start the unlock / warn time period (one day in the future).
export async function orchidUnlock(): Promise<string> {
  const accounts = await web3.eth.getAccounts();
  return evalOrchidTx(
      OrchidContracts.lottery.methods.warn().send({
        from: accounts[0],
        gas: OrchidContracts.lottery_warn_max_gas
      })
  );
}

export async function orchidBindSigner(signer: Address): Promise<string> {
  const accounts = await web3.eth.getAccounts();
  return evalOrchidTx(
      OrchidContracts.lottery.methods.bind(signer).send({
        from: accounts[0],
        gas: OrchidContracts.lottery_bind_max_gas
      })
  );
}

/// Get the lottery pot balance and escrow amount for the specified address.
export async function orchidGetLotteryPot(address: Address): Promise<LotteryPot | null> {
  const accounts = await web3.eth.getAccounts();
  let result = await OrchidContracts.lottery.methods.look(address).call({from: accounts[0],});
  if (result == null || result._length < 3) {
    return null;
  }
  const balance: BigInt = result[0];
  const escrow: BigInt = result[1];
  const unlock: number = Number(result[2]);
  const unlockDate: Date | null = unlock > 0 ? new Date(unlock * 1000) : null;
  console.log("Pot info: ", balance, "escrow: ", escrow, "unlock: ", unlock, "unlock date:", unlockDate);
  return new LotteryPot(balance, escrow, unlockDate);
}

export function isEthAddress(str: string): boolean {
  return web3.utils.isAddress(str);
}

// Convert a wei value (string or number) to an OXT String rounded to the specified
// number of decimal places.
export function weiToOxtString(wei: BigInt, decimals: number) {
  decimals = Math.round(decimals);
  let val = parseFloat(web3.utils.fromWei(wei.toString()));
  return (Math.round(val * (10 * decimals)) / (10 * decimals)).toString();
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
