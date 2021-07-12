import React, {FC, useEffect, useState} from 'react'
import {render} from 'react-dom'
import {OrchidAPI} from "./api/orchid-api";

import 'bootstrap/dist/css/bootstrap.css'
import './index.css'
import './css/app-style.css'
import './css/form-style.css'
import './css/button-style.css'
import {Layout} from "./components/Layout"
import {createIntl, createIntlCache, IntlProvider} from "react-intl";
import messages_en from './i18n/en.json';
import messages_zh from './i18n/zh.json';
import messages_ru from './i18n/ru.json';
import messages_id from './i18n/id.json';
import messages_ja from './i18n/ja.json';
import messages_ko from './i18n/ko.json';
import {getParam, hashPath, testLocalization_} from "./util/util";
import {
  pathToRoute,
  Route,
  RouteContext,
  setURL
} from "./components/RouteContext";
import {WalletProviderState, WalletProviderStatus} from "./api/orchid-eth-web3";
import {Subscription} from "rxjs";
import {LotteryPot, Wallet} from "./api/orchid-eth-types";
import {NoWallet} from "./components/NoWallet";

//const messages: Record<string, Record<string, any>> = {
const messages: any = {
  'en': messages_en,
  'zh': messages_zh,
  'ru': messages_ru,
  'id': messages_id,
  'ja': messages_ja,
  'ko': messages_ko,
};

let language = navigator.language.split(/[-_]/)[0]; // TODO: country
if (getParam('testLocalization')) {
  // Spanish number / date formatting with mixed case English
  language = 'es';
  messages[language] = testLocalization_(messages['en']);
}

const cache = createIntlCache();
export const intl = createIntl({
  locale: language,
  messages: messages[language]
}, cache);

export const WalletProviderContext = React.createContext(WalletProviderStatus.unknown)
export const WalletContext = React.createContext<Wallet | null>(null)
export const ApiContext = React.createContext(OrchidAPI.shared())
export const AccountContext = React.createContext<LotteryPot | null>(null)

const App: FC = () => {
  const [route, setRoute] = useState<Route>(pathToRoute(hashPath()) ?? Route.None);
  const [walletProviderStatus, setWalletProviderStatus] = useState(WalletProviderStatus.unknown);
  const [wallet, setWallet] = useState<Wallet | null>(null);
  const [pot, setPot] = useState<LotteryPot | null>(null);

  useEffect(() => {
      let subscriptions: Subscription [] = [];
      let api = OrchidAPI.shared();

      subscriptions.push(api.provider.walletStatus.subscribe(newWalletStatus => {
        console.log("new wallet status: ", WalletProviderState[newWalletStatus.state], newWalletStatus.account/*, walletProviderStatus.account*/);
        // If no account or account has chnaged, default the route
        if (!newWalletStatus.account || (walletProviderStatus.account && newWalletStatus.account !== walletProviderStatus.account)) {
          console.log("new wallet account: clearing route")
          setURL(Route.None)
        }
        setWalletProviderStatus(newWalletStatus);
      }));

      subscriptions.push(api.wallet.subscribe(wallet => {
        setWallet(wallet ?? null)
      }));

      subscriptions.push(api.lotteryPot.subscribe(async pot => {
        setPot(pot)
      }));

      return () => {
        subscriptions.forEach(sub => {
          sub.unsubscribe()
        })
      };
    },
    // Note: The dependency on the old account value here means that this will be recreated on each change.
    // Note: this is ok, just creates unnecessary unsub/re-sub and duplicate log messages.
    [walletProviderStatus.account]);

  let routeContextValue = {
    route: route,
    setRoute: (route: Route) => {
      setRoute(route);
      setURL(route);
    }
  };


  let api = OrchidAPI.shared();
  console.log("contracts overridden = ", api.eth?.contractsOverridden);
  // Key on any change in chain, network, or account to clear UI state.
  return (
    <RouteContext.Provider value={routeContextValue}>
      <ApiContext.Provider value={OrchidAPI.shared()}>
        <WalletProviderContext.Provider value={walletProviderStatus}>
          <WalletContext.Provider value={wallet}>
            <AccountContext.Provider value={pot}>
              {
                // For now limit to main net V0
                (walletProviderStatus.chainInfo?.isEthereumMainNet || api.eth?.contractsOverridden) ?
                  <Layout
                    key={walletProviderStatus.chainId + ":" + walletProviderStatus.networkId + ":" + walletProviderStatus.account}/>
                  : <NoWallet walletStatus={walletProviderStatus}/>
              }
            </AccountContext.Provider>
          </WalletContext.Provider>
        </WalletProviderContext.Provider>
      </ApiContext.Provider>
    </RouteContext.Provider>
  )
};
const Placeholder: FC = () => {
  return <div>Loading...</div>
};

OrchidAPI.shared().init((startupComplete) => {
  console.log("startup complete: ", startupComplete);
  render(
    <IntlProvider locale={language} messages={messages[language]}>
      {startupComplete ? <App/> : <Placeholder/>}
    </IntlProvider>,
    document.getElementById('root')
  );
});

