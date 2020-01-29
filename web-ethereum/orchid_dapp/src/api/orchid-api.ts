/* eslint-disable @typescript-eslint/no-use-before-define */
import {Wallet, LotteryPot, Signer, OrchidEthereumAPI} from "./orchid-eth";
import {BehaviorSubject, Observable, of} from "rxjs";
import {filter, flatMap, map, shareReplay} from "rxjs/operators";
import {EtherscanIO, LotteryPotUpdateEvent} from "./etherscan-io";
import {isDefined, isNotNull} from "./orchid-types";
import {OrchidTransactionDetail, OrchidTransactionMonitor} from "./orchid-tx";

/// The high level API for observation of a user's Ethereum wallet and lottery pot state.
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

  // The Orchid Ethereum API
  // eth = new MockQuickSetup();
  eth = new OrchidEthereumAPI();

  // The Orchid transaction monitor
  // transactionMonitor = new MockOrchidTransactionMonitor();
  transactionMonitor = new OrchidTransactionMonitor();

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
  lotteryPot: Observable<LotteryPot | null> = this.signer.pipe(
    // flatMap here resolves the promises
    flatMap((signer: Signer | undefined) => {
      if (signer === undefined) {
        return of(null); // flatMap requires observables, even for null
      }
      try {
        return this.eth.orchidGetLotteryPot(signer.wallet, signer);
      } catch (err) {
        console.log("lotteryPot: Error getting lottery pot data for signer: ", signer);
        this.walletStatus.next(WalletStatus.Error);
        throw err;
      }
    }), shareReplay(1)
  );
  lotteryPot_wait: Observable<LotteryPot> = this.lotteryPot.pipe(filter(isNotNull), shareReplay(1));

  // Funding transactions on the current wallet
  transactions = new BehaviorSubject<LotteryPotUpdateEvent[] | null>(null);
  transactions_wait: Observable<LotteryPotUpdateEvent[]> = this.transactions.pipe(filter(isNotNull), shareReplay(1));

  // Currently monitored user transactions on Ethereum
  orchid_transactions = new BehaviorSubject<OrchidTransactionDetail [] | undefined>(undefined);
  orchid_transactions_wait: Observable<OrchidTransactionDetail []> = this.orchid_transactions.pipe(filter(isDefined), shareReplay(1));

  // Logging
  debugLog = "";
  debugLogChanged = new BehaviorSubject(true);

  async init(listenForProviderChanges: boolean = true): Promise<WalletStatus> {
    if (OrchidAPI.isMobileDevice()) {
      this.captureLogs();
    }

    const propsUpdate = listenForProviderChanges ?
      (props: any) => {
        console.log("provider props changed: ", props);
        this.init(false);
      } : undefined;

    let status = await this.eth.orchidInitEthereum(propsUpdate);
    if (status === WalletStatus.Connected) {
      await this.updateWallet();
      await this.updateSigners();
      this.updateTransactions();
    }
    this.walletStatus.next(status);

    // Init the transaction monitor
    this.transactionMonitor.init(transactions => {
      // TODO: Update the wallet / signers here if a transaction changed status
      if (transactions.length > 0) {
        console.log("txs: ", transactions.toString());
      }
      this.orchid_transactions.next(transactions);
    });

    return status;
  }

  async updateSigners() {
    let wallet = this.wallet.value;
    if (wallet === undefined) {
      return;
    }
    try {
      console.log("get signers");
      let signers = await this.eth.orchidGetSigners(wallet);
      console.log("got signers");
      this.signersAvailable.next(signers);

      // no signers available
      if (signers.length === 0) {
        this.signer.next(undefined);
        return;
      }

      // Select the first if available as default
      if (!this.signer.value) {
        console.log("updateSigners setting default signer: ", signers[0]);
        this.signer.next(signers[0]);
      }
    } catch (err) {
      console.log("Error updating signers: ", err);
      this.walletStatus.next(WalletStatus.Error);
      this.signer.next(undefined);
    }
  }

  async updateWallet() {
    try {
      this.wallet.next(await this.eth.orchidGetWallet());
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
    let io = new EtherscanIO();
    let funder = this.wallet.value;
    let signer = this.signer.value;
    if (!funder || !signer) {
      //console.log("can't update transactions, missing funder or signer");
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

export enum WalletStatus {
  NoWallet, NotConnected, Connected, Error, WrongNetwork
}

