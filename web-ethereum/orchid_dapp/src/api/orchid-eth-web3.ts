//
// Orchid Web3 Provider API
//
import {OrchidContracts} from "./orchid-eth-contracts";
import Web3 from "web3";
import "../i18n/i18n_util";
import {BehaviorSubject} from "rxjs";

declare global {
  interface Window {
    ethereum: any
    web3: any
  }
}

/// Discovery and initialization of the web3 provider.
/// Relevant standards:
/// https://eips.ethereum.org/EIPS/eip-1193 (supported events)
/// https://nodejs.org/api/events.html (event emitter API)
export class OrchidWeb3API {
  web3: Web3 | null = null;

  // Wallet connection or error status.
  walletStatus = new BehaviorSubject<WalletProviderStatus>(WalletProviderStatus.unknown);

  /// Init the Web3 environment and the Orchid contracts.
  /// The wallet status should be monitored for connection status.
  constructor() {
    console.log("eth: orchidInitEthereum")
    if (window.ethereum) {
      window.ethereum.autoRefreshOnNetworkChange = false;
      this.web3 = new Web3(window.ethereum);
    } else if (window.web3) {
      console.log("Legacy dapp browser.");
      this.web3 = new Web3(window.web3.currentProvider);
    } else {
      console.log('Non-Ethereum browser.');
      // There is no eth provider: we should prompt the user to install one and reload the page.
      this.walletStatus.next(WalletProviderStatus.noWalletProvider)
      return;
    }

    // Listen for connection status
    this.registerListeners();

    // Init contracts
    try {
      OrchidContracts.token = new this.web3.eth.Contract(OrchidContracts.token_abi, OrchidContracts.token_addr());
      OrchidContracts.lottery = new this.web3.eth.Contract(OrchidContracts.lottery_abi, OrchidContracts.lottery_addr());
      OrchidContracts.directory = new this.web3.eth.Contract(OrchidContracts.directory_abi, OrchidContracts.directory_addr());
    } catch (err) {
      console.log("Error constructing contracts");
      this.walletStatus.next(WalletProviderStatus.error);
    }

    (window as any).web3 = this.web3; // replace any injected version
  }

  registerListeners() {
    if (!window.ethereum.on) {
      // We could try to fall back to the old provider APIs here.
      console.log("No EIP-1193 event emitter available");
      return;
    }
    try {
      console.log("registering account listener");
      window.ethereum.on('accountsChanged', (accounts: Array<string>) => {
        this.accountsChanged(accounts)
      })
      window.ethereum.on('chainChanged', (props: any) => {
        this.chainOrNetworkChanged().then();
      })
      window.ethereum.on('networkChanged', (props: any) => {
        this.chainOrNetworkChanged().then();
      })
    } catch (err) {
      console.log("error registering listener: ", err)
    }
  }

  /// Handle web3 provider account changes.
  /// We expect this to be called at least once on page load (eip-1193)
  accountsChanged(accounts: Array<string>) {
    console.log("web3 provider accounts changed: ", accounts)
    this.walletStatus.next(
      accounts.length > 0 ?
        WalletProviderStatus.connected(accounts[0])
        : WalletProviderStatus.notConnected
    )
  }

  /// Check for the main network
  /// We expect this to be called at least once on page load (eip-1193)
  async chainOrNetworkChanged() {
    console.log("web3 provider chain or network changed")
    if (this.walletStatus.value.state === WalletProviderState.Connected) {
      let networkId = this.web3 && await this.web3.eth.net.getId();
      let chainId = this.web3 && await this.web3.eth.getChainId();
      if (networkId === this.walletStatus.value.networkId
        && chainId === this.walletStatus.value.chainId) {
        console.log("ignoring duplicate")
        return; // ignore duplicate
      }
      this.walletStatus.next(WalletProviderStatus.connected(
        this.walletStatus.value.account ?? "",
        chainId ?? undefined,
        networkId ?? undefined
      ));
    }
  }

  /// Prompt account connection UI on the provider
  async connect() {
    try {
      // TODO: We should first detect if we are already connected using:
      // TODO: ethereum.on('accountsChanged', ...); which fires on page load.
      if (window.ethereum.on) {
        // This is the recommended way to trigger the account connection
        // https://eips.ethereum.org/EIPS/eip-1102 (request accounts)
        console.log("init eth connection");
        await window.ethereum.request({method: 'eth_requestAccounts'})
      } else {
        // This is the legacy enable method.
        console.log("legacy init eth connection");
        await window.ethereum.enable();
      }
    } catch (error) {
      // resolve(WalletProviderStatus.notConnected);
      console.log("User denied account access...");
    }
  }
}

export enum WalletProviderState {
  // Status not yet determined
  Unknown,

  // No injected ethereum provider
  NoWalletProvider,

  // Ethererum provider injected but no accounts yet offered
  NotConnected,

  // Ethereum provider injected and accounts available
  Connected,

  // There was an error when attempting to ask the ethereum provider for accounts
  Error,

  // The ethereum provider is on the wrong network or chain
  WrongNetworkOrChain
}

// The web3 provider status
export class WalletProviderStatus {
  state: WalletProviderState;
  account: string | undefined
  chainId: number | undefined
  networkId: number | undefined

  static unknown = new WalletProviderStatus(WalletProviderState.Unknown)
  static noWalletProvider = new WalletProviderStatus(WalletProviderState.NoWalletProvider)
  static notConnected = new WalletProviderStatus(WalletProviderState.NotConnected)
  static error = new WalletProviderStatus(WalletProviderState.Error)
  static wrongNetworkOrChain = new WalletProviderStatus(WalletProviderState.WrongNetworkOrChain)

  static connected(account: string, chainId?: number, networkId?: number) {
    return new WalletProviderStatus(WalletProviderState.Connected, account, chainId, networkId)
  }

  constructor(state: WalletProviderState, account?: string, chainId?: number, networkId?: number) {
    this.state = state;
    this.account = account;
    this.chainId = chainId
    this.networkId = networkId
  }
}

