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
}

// The web3 provider status
export class WalletProviderStatus {
  state: WalletProviderState;
  account: string | undefined
  chainId: number | undefined
  networkId: number | undefined

  static unknown = new WalletProviderStatus(WalletProviderState.Unknown)
  static noWalletProvider = new WalletProviderStatus(WalletProviderState.NoWalletProvider)
  static error = new WalletProviderStatus(WalletProviderState.Error)

  static connected(account: string, chainId?: number, networkId?: number) {
    return new WalletProviderStatus(WalletProviderState.Connected, account, chainId, networkId)
  }

  static notConnected(chainId?: number, networkId?: number) {
    return new WalletProviderStatus(WalletProviderState.NotConnected, undefined, chainId, networkId)
  }

  constructor(state: WalletProviderState, account?: string, chainId?: number, networkId?: number) {
    this.state = state;
    this.account = account;
    this.chainId = chainId
    this.networkId = networkId
  }

  isMainNet(): boolean {
    // TODO: we need a table here
    return this.chainId === 1;
  }
}


/// Discovery and initialization of the web3 provider.
/// Relevant standards:
/// https://eips.ethereum.org/EIPS/eip-1193 (eth provider events)
/// https://eips.ethereum.org/EIPS/eip-1102 (account authorization)
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
    this.registerListeners().then();

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

  async registerListeners() {
    console.log("web3: register listeners");

    if (!window.ethereum.on) {
      // Fall back to the old provider APIs here.
      console.log("No EIP-1193 event emitter available");
      try {
        await this.connect();
        await this.chainOrNetworkChanged();
        window.ethereum.send('eth_accounts').then((response: any) => {
          this.accountsChanged(response.result);
        });
      } catch (err) {
        console.log("web3: error, defaulting accounts: ", err);
        await this.accountsChanged([]);
      }
      return;
    }

    // EIP-1193 listeners
    try {
      console.log("registering eip-1193 listeners");
      window.ethereum.on('accountsChanged', (accounts: Array<string>) => {
        console.log("web3: listener accounts changed")
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

    // EIP-1193 accounts fetch
    window.ethereum.send('eth_accounts')
      .then((response: any) => {
        console.log("web3: request eth_accounts result: ", response)
        this.accountsChanged(response.result)
      })
      .catch((err: any) => {
        console.log("web3: request eth_accounts err: ", err)
        if (err.code === 4100) { // EIP 1193 unauthorized error
          console.log('Error 4100.')
          this.accountsChanged([]);
        } else {
          console.error('web3: eth_accounts: ', err);
          this.walletStatus.next(WalletProviderStatus.error);
        }
      })

    // EIP-1193 chain fetch
    window.ethereum.send('eth_chainId')
      .then(() => {
        this.chainOrNetworkChanged().then();
      })
      .catch((err: any) => {
        console.error('web3: eth_chainId', err);
        this.walletStatus.next(WalletProviderStatus.error);
      });
  }

  /// Handle web3 provider account changes.
  async accountsChanged(accountsIn: Array<string>) {
    console.log("web3 provider accounts changed: ", accountsIn)
    let accounts: Array<string> = accountsIn;
    if (accounts.length === 0) {
      try {
        // Attempt to re-fetch the accounts.
        accounts = (this.web3 && await this.web3.eth.getAccounts()) ?? [];
        console.log("web3 re-fetched accounts: ", accounts)
      } catch (err) {
        console.log("web3: error attempting to fetch accounts");
      }
    }
    let state = accounts.length > 0 ? WalletProviderState.Connected : WalletProviderState.NotConnected;
    let account = accounts.length > 0 ? accounts[0] : undefined
    this.walletStatus.next(
      new WalletProviderStatus(
        state, account,
        this.walletStatus.value.chainId,
        this.walletStatus.value.networkId
      ));
  }

  /// Check for the main network
  /// We expect this to be called at least once on page load (eip-1193)
  async chainOrNetworkChanged() {
    let networkId = this.web3 && await this.web3.eth.net.getId();
    let chainId = this.web3 && await this.web3.eth.getChainId();
    console.log("web3 provider chain or network changed: ", chainId, networkId)
    if (networkId === this.walletStatus.value.networkId
      && chainId === this.walletStatus.value.chainId) {
      console.log("ignoring duplicate")
      return; // ignore duplicate
    }
    this.walletStatus.next(
      new WalletProviderStatus(
        this.walletStatus.value.state,
        this.walletStatus.value.account,
        chainId ?? undefined,
        networkId ?? undefined
      ));
  }

  /// Prompt account connection UI on the provider
  /// EIP-1102 user authorization / connection
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
