import {Account, LotteryPot, orchidGetAccount, orchidGetLotteryPot, orchidInitEthereum} from "./orchid-eth";
import {BehaviorSubject, Observable} from "rxjs";
import {filter, flatMap} from "rxjs/operators";
import {EtherscanIO, LotteryPotUpdateEvent} from "./etherscan-io";
import {isNotNull} from "./orchid-types";

export enum WalletStatus {
  NoWallet, NotConnected, Connected, Error
}

export class OrchidAPI {
  private static instance: OrchidAPI;

  private constructor() {
  }

  static shared() {
    if (!OrchidAPI.instance) {
      OrchidAPI.instance = new OrchidAPI();
    }
    return OrchidAPI.instance;
  }

  // Rx model
  transactions = new BehaviorSubject<LotteryPotUpdateEvent[] | null>(null);
  transactions_wait: Observable<LotteryPotUpdateEvent[]> = this.transactions.pipe(filter(isNotNull));

  account = new BehaviorSubject<Account | null>(null);
  account_wait: Observable<Account> = this.account.pipe(filter(isNotNull));

  lotteryPot = this.account_wait.pipe(
      flatMap((account: Account) => { // flatMap resolves promises
        return orchidGetLotteryPot(account.address);
      })
  );
  lotteryPot_wait: Observable<LotteryPot> = this.lotteryPot.pipe(filter(isNotNull));

  debugLog = "";
  debugLogChanged = new BehaviorSubject(true);

  async init(): Promise<WalletStatus> {
    this.captureLogs();

    // Allow init ethereum to create the web3 context for validation
    let status =  await orchidInitEthereum();
    if (status == WalletStatus.Connected) {
      this.updateAccount();
      this.updateTransactions();
    }
    return status;
  }

  async updateAccount() {
    this.account.next(await orchidGetAccount());
  }

  async updateTransactions() {
    let io = new EtherscanIO();
    let account = await orchidGetAccount();
    let events: LotteryPotUpdateEvent[] = await io.getEvents(account.address); // Pot address is now the funder address
    this.transactions.next(events);
  }

  private captureLogs() {
    let api = this;
    console.log = function (...args: (any | undefined)[]) {
      // args = args.map(arg => {
      //     if (typeof arg == "string" || typeof arg == "number") {
      //         return arg
      //     } else {
      //         return JSON.stringify(arg)
      //     }
      // });
      api.debugLog += "<span>Log: " + args.join(" ") + "</span><br/>";
      api.debugLogChanged.next(true);
    };
    // Capture errors
    window.onerror = function (message, source, lineno, colno, error) {
      let text = message.toString();
      if (error && error.stack) { text = error.stack.toString() };
      console.log('Error: ' + text + ": " + error);
      console.log('Error json: ', JSON.stringify(error));
    };
    window.onload = function () {
      console.log("Loaded.");
    };
  }
}



