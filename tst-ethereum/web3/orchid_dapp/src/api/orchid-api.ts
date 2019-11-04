import {
  Wallet,
  LotteryPot,
  orchidGetWallet,
  orchidGetLotteryPot,
  orchidInitEthereum,
  Signer, orchidGetSigners
} from "./orchid-eth";
import {BehaviorSubject, Observable} from "rxjs";
import {filter, flatMap, map} from "rxjs/operators";
import {EtherscanIO, LotteryPotUpdateEvent} from "./etherscan-io";
import {isDefined, isNotNull} from "./orchid-types";

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

  // The current wallet
  wallet = new BehaviorSubject<Wallet | undefined>(undefined);
  wallet_wait: Observable<Wallet> = this.wallet.pipe(filter(isDefined));

  // The list of available signer accounts
  signersAvailable = new BehaviorSubject<Signer [] | undefined>(undefined);
  signersAvailable_wait: Observable<Signer []> = this.signersAvailable.pipe(filter(isDefined));

  // True if the user has no signer accounts configured yet.
  newUser_wait: Observable<boolean> = this.signersAvailable_wait.pipe(
    map( (signers: Signer [])=>{ return signers.length === 0 } )
  );


  // The currently selected signer account
  signer = new BehaviorSubject<Signer | undefined>(undefined);
  signer_wait: Observable<Signer> = this.signer.pipe(filter(isDefined));

  // The Lottery pot associated with the currently selected signer account.
  lotteryPot = this.signer_wait.pipe(
      flatMap((signer: Signer) => { // flatMap resolves promises
        return orchidGetLotteryPot(signer.wallet, signer);
      })
  );
  lotteryPot_wait: Observable<LotteryPot> = this.lotteryPot.pipe(filter(isNotNull));

  // Funding transactions on the current wallet
  transactions = new BehaviorSubject<LotteryPotUpdateEvent[] | null>(null);
  transactions_wait: Observable<LotteryPotUpdateEvent[]> = this.transactions.pipe(filter(isNotNull));

  // Logging
  debugLog = "";
  debugLogChanged = new BehaviorSubject(true);

  async init(): Promise<WalletStatus> {
    this.captureLogs();

    // Allow init ethereum to create the web3 context for validation
    let status =  await orchidInitEthereum();
    if (status === WalletStatus.Connected) {
      await this.updateWallet();
      this.updateSigners();
      this.updateTransactions();
    }
    return status;
  }

  async updateSigners() {
    if (this.wallet.value == null) { return; }
    let signers = await orchidGetSigners(this.wallet.value);
    this.signersAvailable.next(signers);
    // Select the first if available
    if (!this.signer.value && signers.length > 0) {
      this.signer.next(signers[0]);
    }
  }

  async updateWallet() {
    this.wallet.next(await orchidGetWallet());
  }

  /// Update selected lottery pot balances
  async updateLotteryPot() {
    this.signer.next(this.signer.value); // Set the signer again to trigger a refresh
  }

  async updateTransactions() {
    let io = new EtherscanIO();
    let account = await orchidGetWallet();
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



