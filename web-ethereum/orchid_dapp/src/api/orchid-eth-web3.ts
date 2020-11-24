//
// Orchid Web3 Provider API
//
import {OrchidContracts} from "./orchid-eth-contracts";
import Web3 from "web3";
import "../i18n/i18n_util";
import {BehaviorSubject} from "rxjs";
import Web3Modal from "web3modal";
import WalletConnectProvider from "@walletconnect/web3-provider";
import {OrchidAPI} from "./orchid-api";

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
  web3Modal: Web3Modal;

  // Wallet connection or error status.
  walletStatus = new BehaviorSubject<WalletProviderStatus>(WalletProviderStatus.unknown);

  private deregisterListeners: (() => void) | undefined;

  constructor() {
    // web3modal providers
    const providerOptions = {
        walletconnect: {
          package: WalletConnectProvider,
          options: {
            infuraId: "63c2f3be7b02422d821307f1270e5baf"
          }
        },
    };

    // web3modal
    this.web3Modal = new Web3Modal({
      cacheProvider: true,
      providerOptions,
      disableInjectedProvider: false,
    });

    this.init().then();
  }

  /// Init the Web3 environment and the Orchid contracts.
  /// The wallet status should be monitored for connection status.
  async init() {
    //console.log("eth: orchidInitEthereum")
    // Look for a cached or default provider
    this.connect().then();
  }

  currentProvider: any | null = null;

  // Connect to a web3 provider. If userInitiatedConnection is true the provider may prompt
  // for a wallet choice or show a dialog initiating authorization of an account.
  async connect(userInitiatedConnect: boolean = false) {

    this.currentProvider = null;
    let provider: any | null = null;

    // Init the web3modal provider if there is a cached wallet selection (no modal)
    // or to prompt for a user-inititated wallet choice (show the modal).
    if (userInitiatedConnect || this.web3Modal.cachedProvider) {
      try {
        // TODO: TESTING: disable web3modal
        provider = await this.connectWeb3Modal()
        console.log("web3: connected web3modal, provider: ", provider)
      } catch (err) {
        console.log("web3: error connecting web3modal")
      }
    }

    // If no web3modal provider was found use the default injected environment.
    // Note: If we do this there is currently no way to disconnect metmask once authorized.
    /*
    if (!provider) {
      provider = window.ethereum
      // If the user is asking for a connection, prompt the default provider to connect
      // an account, else fall througn and wait to see if a previously connected account
      // is injected.
      if (userInitiatedConnect) {
        await this.connectDefaultProvider(provider)
      }
    }*/

    // No provider found, give up.
    if (!provider) {
      this.walletStatus.next(WalletProviderStatus.noWalletProvider);
      return;
    }
    this.currentProvider = provider;

    // Finish web3 init with the provider
    console.log("web3: provider = ", provider)
    this.web3 = new Web3(provider);
    (window as any).web3 = this.web3; // replace any injected version

    // We now have either a web3modal provider or we should look for a default injected environment
    await this.registerListeners(provider);
    this.initContracts();
  }

  async disconnect() {
    console.log("web3: disconnect, provider = ", this.currentProvider)
    console.log("web3: disconnect, window.ethereum = ", window.ethereum)
    if (this.currentProvider?.close) {
      await this.currentProvider.close();
    }
    if (this.currentProvider?.disable) {
      await this.currentProvider.disable();
    }
    if (window.ethereum.disable) {
      await window.ethereum?.disable();
    }
    await this.web3Modal.clearCachedProvider();
    this.currentProvider = null;
    this.walletStatus.next(WalletProviderStatus.noWalletProvider);
    OrchidAPI.shared().clear();
  }

  private async registerListeners(provider: any) {
    console.log("web3: register listeners");

    if (this.deregisterListeners) {
      console.log("web3: de-registering old listeners")
      this.deregisterListeners();
    }

    if (!provider.on) {
      // Fall back to the old provider APIs here.
      console.log("No EIP-1193 event emitter available");
      try {
        await this.connectDefaultProvider(provider);
      } catch (err) {
        console.log("web3: error: ", err);
      }
      return;
    }

    const accountsChangedCallback = (accounts: Array<string>) => {
      console.log("web3: listener accounts changed")
      this.accountsChanged(accounts)
    }
    const chainOrNetworkChangedCallback = (props: any) => {
      console.log("web3 provider chain or network changed: ", props)
      this.chainOrNetworkChanged().then();
    }
    const disconnectOrCloseCallback = () => {
      console.log("web3 provider disconnectOrClose")
      this.walletStatus.next(WalletProviderStatus.noWalletProvider);
    }

    this.deregisterListeners = () => {
      provider.removeListener('accountsChanged', accountsChangedCallback);
      provider.removeListener('chainChanged', chainOrNetworkChangedCallback)
      provider.removeListener('networkChanged', chainOrNetworkChangedCallback)
      provider.removeListener('disconnect', disconnectOrCloseCallback)
      provider.removeListener('close', disconnectOrCloseCallback)
    }

    // EIP-1193 listeners using Node event emitter API (https://nodejs.org/api/events.html)
    try {
      console.log("registering eip-1193 listeners");
      provider.on('accountsChanged', accountsChangedCallback);
      provider.on('chainChanged', chainOrNetworkChangedCallback)
      provider.on('networkChanged', chainOrNetworkChangedCallback)
      provider.on('disconnect', disconnectOrCloseCallback)
      provider.on('close', disconnectOrCloseCallback)
    } catch (err) {
      console.log("error registering listener: ", err)
    }

    // EIP-1193 initial accounts fetch
    if (provider.send) {
      console.log("web3: initializing provider send")

      try {
        let response = await provider.send('eth_accounts')
        console.log("web3: request eth_accounts result: ", response.result)
        await this.accountsChanged(response.result)
      } catch (err: any) {
        console.log("web3: request eth_accounts err: ", err)
        if (err.code === 4100) { // EIP 1193 unauthorized error
          console.log('Error 4100.')
          this.accountsChanged([]);
        } else {
          console.error('web3: eth_accounts: ', err);
        }
        this.walletStatus.next(WalletProviderStatus.error);
      }

      /*
      // Trust wallet appears to support EIP-1193 listeners but doesn't support send properly.
      // EIP-1193 initial accounts fetch
      console.log("web3: send eth_accounts")
      try {
        provider.send('eth_accounts', (response: any) => {
          console.log("web3: request eth_accounts result: ", response.result)
          this.accountsChanged(response.result)
        })
      } catch (err: any) {
        console.log("web3: request eth_accounts err: ", err)
        if (err.code === 4100) { // EIP 1193 unauthorized error
          console.log('Error 4100.')
          this.accountsChanged([]);
        } else {
          console.error('web3: eth_accounts: ', err);
          //this.walletStatus.next(WalletProviderStatus.error);
        }
      }*/

      // EIP-1193 chain fetch
      try {
        await provider.send('eth_chainId')
        this.chainOrNetworkChanged().then();
      } catch (err: any) {
        console.error('web3: eth_chainId', err);
        this.walletStatus.next(WalletProviderStatus.error);
      }
      /*
      // EIP-1193 chain fetch
      // Trust wallet appears to support EIP-1193 listeners but doesn't support send properly.
      console.log("web3: send eth_chainId")
      try {
        provider.send('eth_chainId', () => {
          this.chainOrNetworkChanged().then();
        })
      } catch (err: any) {
        console.error('web3: eth_chainId', err);
        //this.walletStatus.next(WalletProviderStatus.error);
      }
       */

      console.log("web3: Setting timer for checking provider state")
      setTimeout(() => {
        console.log("web3: Checking provider state")
        if (this.walletStatus.value.state !== WalletProviderState.Connected) {
          this.connectDefaultProvider(provider).then();
        }
      }, 750);
    } else {
      console.log("web3: provider has no send method, falling back to default.")
      this.connectDefaultProvider(provider).then();
    }
  }

  /// Handle web3 provider account changes.
  async accountsChanged(accountsIn: Array<string> | null) {
    console.log("web3: provider accounts changed: ", accountsIn)
    let accounts: Array<string> = accountsIn || [];
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
    console.log("web3: chain or network changed, provider: ", this.web3?.currentProvider)
    let networkId = this.web3 && await this.web3.eth.net.getId();
    let chainId = this.web3 && await this.web3.eth.getChainId();
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
  private async connectDefaultProvider(provider: any) {
    console.log("web3: trying to connect default provider.")
    try {
      if (provider.on) {
        // This is the recommended way to trigger the account connection
        // https://eips.ethereum.org/EIPS/eip-1102 (request accounts)
        console.log("init eth connection");
        await provider.request({method: 'eth_requestAccounts'})
      } else {
        // This is the legacy enable method.
        console.log("legacy init eth connection");
        await provider.enable();
      }
    } catch (error) {
      this.walletStatus.next(WalletProviderStatus.noWalletProvider);
      console.log("User denied account access...");
    }
    await this.chainOrNetworkChanged();
    await this.accountsChanged([]);
  }

  /// Prompt account connection UI on the provider
  /// EIP-1102 user authorization / connection
  private async connectWeb3Modal(): Promise<any | null> {
    try {
      return await this.web3Modal.connect();
    } catch (e) {
      console.log("Could not get a wallet connection: ", e);
      this.web3Modal.clearCachedProvider()
      return null;
    }
  }

  private initContracts() {
    if (!this.web3) {
      return
    }

    // Init contracts
    try {
      OrchidContracts.token = new this.web3.eth.Contract(OrchidContracts.token_abi, OrchidContracts.token_addr());
      OrchidContracts.lottery = new this.web3.eth.Contract(OrchidContracts.lottery_abi, OrchidContracts.lottery_addr());
      OrchidContracts.directory = new this.web3.eth.Contract(OrchidContracts.directory_abi, OrchidContracts.directory_addr());
    } catch (err) {
      console.log("Error constructing contracts");
      this.walletStatus.next(WalletProviderStatus.error);
    }

  }

}
