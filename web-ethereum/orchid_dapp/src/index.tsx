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
import {getParam, testLocalization_} from "./util/util";
import {Route, setURL} from "./components/Route";
import {WalletProviderState, WalletProviderStatus} from "./api/orchid-eth-web3";

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

const App: FC = () => {
  const [walletStatus, setWalletStatus] = useState(WalletProviderStatus.unknown);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletStatusSub = api.eth.provider.walletStatus.subscribe(newWalletStatus => {
      console.log("new wallet status: ", WalletProviderState[newWalletStatus.state], newWalletStatus.account);
      if (!newWalletStatus.account || newWalletStatus.account !== walletStatus.account) {
        setURL(Route.None)
      }
      setWalletStatus(newWalletStatus);
    });
    return () => {
      walletStatusSub.unsubscribe();
    };
  },
    // Note: The dependency on the old account value here means that this will be recreated on each change.
    // Note: this is ok, just creates unnecessary unsub/re-sub and duplicate log messages.
    [walletStatus.account]);

  // Key on any change in chain, network, or account to clear UI state.
  return <Layout key={walletStatus.chainId+":"+walletStatus.networkId+":"+walletStatus.account}/>;
};

OrchidAPI.shared().init().then(() => {
  console.log("startup complete: render");
  render(
    <IntlProvider locale={language} messages={messages[language]}>
      <App/>
    </IntlProvider>,
    document.getElementById('root')
  );
});


