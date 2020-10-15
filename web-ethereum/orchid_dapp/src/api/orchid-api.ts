/* eslint-disable @typescript-eslint/no-use-before-define */
import {LotteryPot, OrchidEthereumAPI, Signer, Wallet} from "./orchid-eth";
import {BehaviorSubject, Observable, of} from "rxjs";
import {filter, flatMap, map, shareReplay} from "rxjs/operators";
import {EtherscanIO, LotteryPotUpdateEvent} from "./etherscan-io";
import {isDefined, isNotNull} from "./orchid-types";
import {OrchidTransactionDetail, OrchidTransactionMonitor} from "./orchid-tx";
import {WalletProviderState, WalletProviderStatus} from "./orchid-eth-web3";
// import {MockOrchidTransactionMonitor} from "./orchid-eth-mock";

/// The high level API for observation of a user's wallet and Orchid account state.
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
  //transactionMonitor = new MockOrchidTransactionMonitor();
  transactionMonitor = new OrchidTransactionMonitor();

  // The current wallet
  wallet = new BehaviorSubject<Wallet | undefined>(undefined);
  wallet_wait: Observable<Wallet> = this.wallet.pipe(filter(isDefined), shareReplay(1));

  // The list of available signer accounts
  signersAvailable = new BehaviorSubject<Signer [] | undefined>(undefined);
  signersAvailable_wait: Observable<Signer []> = this.signersAvailable.pipe(filter(isDefined), shareReplay(1));

  // True if the user does not yet have an Orchid account for the current wallet account.
  // This observable blocks until signers list can be fetched from the lottery contract.
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
        //this.walletStatus.next(WalletProviderStatus.error);
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

  updateBalancesTimer: NodeJS.Timeout | null = null

  // Init the high level Orchid API and fetch initial state from the contract
  async init() {
    if (OrchidAPI.isMobileDevice()) {
      this.captureLogs();
    }

    /*
    // Wait for the provider to connect before completing initialization
    this.eth.provider.walletStatus.pipe(
      filter(status => {
        return status.state === WalletProviderState.Connected
      }),
      take(1)
    ).subscribe(() => {
      this.onProviderConnected();
    });
     */

    this.eth.provider.walletStatus.subscribe((status) => {
      // On any change to the wallet (account or chain) refresh everything.
      this.onProviderAccountChange(status);
    });
  }

  // Initialization to be performed after the provider is connected
  private async onProviderAccountChange(status: WalletProviderStatus) {
    console.log("api: on provider account change: ", status.account);
    this.wallet.next(undefined);
    this.signer.next(undefined);
    await this.updateWallet();
    await this.updateSigners();
    this.updateTransactions().then();
    this.initPollingIfNeeded();
  }

  initPollingIfNeeded() {
    // Poll wallet and lottery pot periodically
    if (this.updateBalancesTimer == null) {
      this.updateBalancesTimer = setInterval(() => this.updateBalances(), 10000/*ms*/);
    }

    // Init the transaction monitor
    this.transactionMonitor.initIfNeeded(transactions => {
      // TODO: Update the wallet / signers here if a transaction changed status
      if (transactions.length > 0) {
        console.log("txs: ", transactions.toString());
      }
      this.orchid_transactions.next(transactions);
    });
  }

  async updateSigners() {
    let wallet = this.wallet.value;
    if (wallet === undefined) {
      return;
    }
    try {
      //console.log("get signers");
      let signers = await this.eth.orchidGetSigners(wallet);
      //console.log("got signers");
      this.signersAvailable.next(signers);

      // no signers available
      if (signers.length === 0) {
        this.signer.next(undefined);
        return;
      }

      // Select the first if available as default
      if (!this.signer.value) {
        //console.log("updateSigners setting default signer: ", signers[0]);
        this.signer.next(signers[0]);
      }
    } catch (err) {
      console.log("Error updating signers: ", err);
      //this.walletStatus.next(WalletProviderStatus.error);
      this.signer.next(undefined);
    }
  }

  async updateWallet() {
    // if (this.walletStatus.value.state !== WalletState.Connected) { return }
    try {
      this.wallet.next(await this.eth.orchidGetWallet());
    } catch (err) {
      console.log("Error updating wallet: ");
      //this.walletStatus.next(WalletProviderStatus.error);
    }
  }

  /// Update selected lottery pot balances
  async updateLotteryPot() {
    //console.log("Update lottery pot refreshing signer data: ", this.signer.value);
    this.signer.next(this.signer.value); // Set the signer again to trigger a refresh
  }

  async updateBalances() {
    //console.log("update balances")
    await this.updateWallet();
    await this.updateLotteryPot();
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
