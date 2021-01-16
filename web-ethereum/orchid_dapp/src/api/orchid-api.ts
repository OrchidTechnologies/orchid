/* eslint-disable @typescript-eslint/no-use-before-define */
import {LotteryPot, OrchidEthereumAPI, Signer, Wallet} from "./orchid-eth";
import {BehaviorSubject, Observable, of} from "rxjs";
import {filter, flatMap, map, shareReplay, take} from "rxjs/operators";
import {OrchidTransactionDetail, OrchidTransactionMonitor} from "./orchid-tx";
import {OrchidWeb3API, WalletProviderState, WalletProviderStatus} from "./orchid-eth-web3";
import {debugV0, isDebug, isNotNull} from "../util/util";
import {OrchidEthereumApiV0Impl} from "./v0/orchid-eth-v0";
import {OrchidEthereumApiV1Impl} from "./v1/orchid-eth-v1";
import {LotteryPotUpdateEvent} from "./orchid-eth-types";
// import {MockOrchidTransactionMonitor} from "./orchid-eth-mock";

/// The high level API for observation of a user's wallet and Orchid account state.
export class OrchidAPI {
  private static instance: OrchidAPI;

  private constructor() {
    // Subscribe to changes in wallet status and choose the appropriate orchid lib.
    OrchidWeb3API.shared().walletStatus.subscribe((walletStatus) => {
      if (walletStatus === WalletProviderStatus.error) { return }
      try {
        let web3 = OrchidWeb3API.shared().web3;
        if (!web3) {
          console.log("no web3 provider");
          return;
        }
        if (!walletStatus.chainInfo) {
          console.log(`Missing chain info: ${walletStatus.chainInfo}`);
          return;
        }
        if (walletStatus.chainInfo.isEthereumMainNet || debugV0()) {
          this.eth = new OrchidEthereumApiV0Impl(web3) as OrchidEthereumAPI;
        } else {
          // Assume v1 contract for now
          this.eth = new OrchidEthereumApiV1Impl(web3, walletStatus.chainInfo) as OrchidEthereumAPI;
        }
      } catch (err) {
        console.log("Error constructing contracts: ", err);
        this.eth = null;
        this.provider.walletStatus.next(WalletProviderStatus.error);
      }
    });
  }

  static shared() {
    if (!OrchidAPI.instance) {
      OrchidAPI.instance = new OrchidAPI();
    }
    return OrchidAPI.instance;
  }

  eth: OrchidEthereumAPI | null = null

  provider = OrchidWeb3API.shared();

  // The Orchid transaction monitor
  //transactionMonitor = new MockOrchidTransactionMonitor();
  transactionMonitor = new OrchidTransactionMonitor();

  // The current wallet
  wallet = new BehaviorSubject<Wallet | null>(null);

  // The list of available signer accounts
  signersAvailable = new BehaviorSubject<Signer [] | null>(null);

  // True if the user does not yet have an Orchid account for the current wallet account.
  // This defaults to true (new user) until an account is resolved.
  newUser: Observable<boolean> = this.signersAvailable.pipe(
    map((signers: Signer [] | null) => {
      return !signers ? true : signers.length === 0;
    }), shareReplay(1)
  );

  // The currently selected signer account
  signer = new BehaviorSubject<Signer | null>(null);

  // The Lottery pot associated with the currently selected signer account.
  lotteryPot: Observable<LotteryPot | null> = this.signer.pipe(
    // flatMap here resolves the promises
    flatMap((signer: Signer | null) => {
      if (signer === null || this.eth == null) {
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

  // Currently monitored user transactions on Ethereum
  orchid_transactions = new BehaviorSubject<OrchidTransactionDetail [] | undefined>(undefined);

  // Logging
  debugLog = "";
  debugLogChanged = new BehaviorSubject(true);

  updateBalancesTimer: NodeJS.Timeout | null = null

  // Init the high level Orchid API and fetch initial state from the contract
  init(startupCompleteCallback: (startupComplete: boolean) => void) {
    if (OrchidAPI.isMobileDevice() || isDebug()) {
      this.captureLogs();
    }

    startupCompleteCallback(false);

    // Monitor the wallet provider
    this.provider.walletStatus.subscribe((status) => {
      switch (status.state) {
        case WalletProviderState.Unknown:
          break;
        case WalletProviderState.NoWalletProvider:
        case WalletProviderState.NotConnected:
        case WalletProviderState.Error:
          console.log("api: startup complete (no provider or error): ", WalletProviderState[status.state]);
          // Refresh everything to clear any account data.
          this.onProviderAccountChange(status).then();
          // Show the UI
          startupCompleteCallback(true);
          break;
        case WalletProviderState.Connected:
          // Refresh to get the new account data.
          this.onProviderAccountChange(status).then();
          break;
      }
    });

    // Signal startup complete after the new user status is updated (or an error pushes a null status update).
    // (Wait for the first update after the default replay value.)
    let count = 0;
    this.newUser.pipe(take(2)).subscribe((newUser) => {
      console.log("api: newUser = ", newUser)
      if (count++ > 0) {
        console.log("api: startup complete (new user result)")
        // Show the UI
        startupCompleteCallback(true);
      }
    });
  }

  // Initialization to be performed after the provider is connected
  private async onProviderAccountChange(status: WalletProviderStatus) {
    await this.clear();
    if (status.state === WalletProviderState.Connected) {
      await this.updateWallet();
      await this.updateSigners();
      this.updateTransactions().then();
      this.initPollingIfNeeded();
    }
  }

  async clear() {
    //console.log("api: clear wallet")
    if (this.wallet.value) {
      this.wallet.next(null);
    }
    if (this.signersAvailable.value) {
      this.signersAvailable.next(null)
    }
    if (this.signer.value) {
      this.signer.next(null);
    }
    if (this.transactions.value) {
      this.transactions.next(null);
    }
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
        console.log("api: txs: ", transactions.toString());
      }
      this.orchid_transactions.next(transactions);
    });
  }

  async updateSigners() {
    if (!this.eth) {
      return
    }
    console.log("api: update signers");
    let wallet = this.wallet.value;
    if (!wallet) {
      this.signersAvailable.next(null);
      this.signer.next(null);
      return;
    }
    try {
      let signers = await this.eth.orchidGetSigners(wallet);
      this.signersAvailable.next(signers);

      // no signers available
      if (signers.length === 0) {
        this.signer.next(null);
        return;
      }

      // Select the first if available as default
      if (!this.signer.value) {
        //console.log("updateSigners setting default signer: ", signers[0]);
        this.signer.next(signers[0]);
      }
    } catch (err) {
      console.log("api: Error updating signers: ", err);
      this.signersAvailable.next(null);
      this.signer.next(null);
    }
  }

  async updateWallet() {
    console.log("update wallet")
    if (!this.eth || this.provider.walletStatus.value.state !== WalletProviderState.Connected) {
      this.wallet.next(null);
      return;
    }
    try {
      if (this.eth) {
        this.wallet.next(await this.eth.orchidGetWallet());
      }
    } catch (err) {
      console.log("api: Error updating wallet: ", err);
    }
  }

  /// Update selected lottery pot balances
  async updateLotteryPot() {
    //console.log("api: Update lottery pot refreshing signer data: ", this.signer.value);
    this.signer.next(this.signer.value); // Set the signer again to trigger a refresh
  }

  async updateBalances() {
    await this.updateWallet();
    await this.updateLotteryPot();
  }

  async updateTransactions() {
    let funder = this.wallet.value;
    let signer = this.signer.value;
    if (!funder || !signer || !this.eth) {
      return;
    }
    let events: LotteryPotUpdateEvent[] = await this.eth.getLotteryUpdateEvents(funder.address, signer.address);
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
      const logLine = "<span>Log: " + args.join(" ") + "</span><br/>"
      api.debugLog += logLine
      api.debugLogChanged.next(true)

      if (isDebug()) {
        let div = document.getElementById('debugLog')
        if (div) {
          div.innerHTML += logLine;
        }
      }
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

    if (isDebug()) {
      let div = document.getElementById('debugLog')
      if (div) {
        div.innerHTML += '<br/><b>Debug Log</b><br/>'
      }
    }
  }

  private static isMobileDevice() {
    return (typeof window.orientation !== "undefined");
  };
}
