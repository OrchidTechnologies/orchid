import {
  Wallet,
  LotteryPot,
  orchidGetWallet,
  orchidGetLotteryPot,
  orchidInitEthereum,
  Signer, orchidGetSigners
} from "./orchid-eth";
import {BehaviorSubject, Observable} from "rxjs";
import {filter, flatMap, map, shareReplay} from "rxjs/operators";
import {EtherscanIO, LotteryPotUpdateEvent} from "./etherscan-io";
import {isDefined, isNotNull} from "./orchid-types";

export enum WalletStatus {
  NoWallet, NotConnected, Connected, Error, WrongNetwork
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

  // Wallet connection or error status.  Wallet.Error may indicate the lack of a valid web3
  // environment or the failure of core contract calls.
  walletStatus = new BehaviorSubject<WalletStatus>(WalletStatus.NotConnected);

  // The current wallet
  wallet = new BehaviorSubject<Wallet | undefined>(undefined);
  wallet_wait: Observable<Wallet> = this.wallet.pipe(filter(isDefined), shareReplay(1));

  // The list of available signer accounts
  signersAvailable = new BehaviorSubject<Signer [] | undefined>(undefined);
  signersAvailable_wait: Observable<Signer []> = this.signersAvailable.pipe(filter(isDefined), shareReplay(1));

  // True if the user has no signer accounts configured yet.
  newUser_wait: Observable<boolean> = this.signersAvailable_wait.pipe(
    map((signers: Signer []) => {
      return signers.length === 0
    }), shareReplay(1)
  );

  // The currently selected signer account
  signer = new BehaviorSubject<Signer | undefined>(undefined);
  signer_wait: Observable<Signer> = this.signer.pipe(filter(isDefined), shareReplay(1));

  // The Lottery pot associated with the currently selected signer account.
  lotteryPot: Observable<LotteryPot | null> = this.signer_wait.pipe(
    flatMap((signer: Signer) => { // flatMap resolves promises
      try {
        return orchidGetLotteryPot(signer.wallet, signer);
      } catch (err) {
        console.log("Error getting lottery pot data for signer: ", signer);
        this.walletStatus.next(WalletStatus.Error);
        throw err;
      }
    }), shareReplay(1)
  );
  lotteryPot_wait: Observable<LotteryPot> = this.lotteryPot.pipe(filter(isNotNull), shareReplay(1));

  // Funding transactions on the current wallet
  transactions = new BehaviorSubject<LotteryPotUpdateEvent[] | null>(null);
  transactions_wait: Observable<LotteryPotUpdateEvent[]> = this.transactions.pipe(filter(isNotNull), shareReplay(1));

  // Logging
  debugLog = "";
  debugLogChanged = new BehaviorSubject(true);

  async init(listenForProviderChanges: boolean = true): Promise<WalletStatus> {
    if (OrchidAPI.isMobileDevice()) {
      this.captureLogs();
    }

    const propsUpdate = listenForProviderChanges ?
      (props: any) => {
        console.log("provider props change: ", props);
        this.init(false);
      } : undefined;

    // Allow init ethereum to create the web3 context for validation
    let status = await orchidInitEthereum(propsUpdate);
    if (status === WalletStatus.Connected) {
      await this.updateWallet();
      await this.updateSigners();
      this.updateTransactions();
    }
    this.walletStatus.next(status);
    return status;
  }

  async updateSigners() {
    if (this.wallet.value == null) {
      return;
    }
    try {
      let signers = await orchidGetSigners(this.wallet.value);
      this.signersAvailable.next(signers);
      // Select the first if available
      if (!this.signer.value && signers.length > 0) {
        console.log("updateSigners setting default signer: ", signers[0]);
        this.signer.next(signers[0]);
      }
    } catch (err) {
      console.log("Error updating signers: ", err);
      this.walletStatus.next(WalletStatus.Error);
    }
  }

  async updateWallet() {
    try {
      this.wallet.next(await orchidGetWallet());
    } catch (err) {
      console.log("Error updating wallet: ", err);
      this.walletStatus.next(WalletStatus.Error);
    }
  }

  /// Update selected lottery pot balances
  async updateLotteryPot() {
    console.log("Update lottery pot refreshing signer data: ", this.signer.value);
    this.signer.next(this.signer.value); // Set the signer again to trigger a refresh
  }

  async updateTransactions() {
    console.log("update transactions");
    let io = new EtherscanIO();
    let funder = this.wallet.value;
    let signer = this.signer.value;
    if (!funder || !signer) {
      console.log("can't update transactions, missing funder or signer");
      return;
    }
    let events: LotteryPotUpdateEvent[] = await io.getEvents(funder.address, signer.address);
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
      if (error && error.stack) {
        text = error.stack.toString()
      }
      ;
      console.log('Error: ' + text + ": " + error);
      console.log('Error json: ', JSON.stringify(error));
    };
    window.onload = function () {
      console.log("Loaded.");
    };
  }

  private static isMobileDevice() {
    return (typeof window.orientation !== "undefined");
  };
}



