import React, {FC, useEffect, useState} from 'react'
import {render} from 'react-dom'
import {OrchidAPI, WalletStatus} from "./api/orchid-api";

import 'bootstrap/dist/css/bootstrap.css'
import './index.css'
import './css/app-style.css'
import './css/form-style.css'
import './css/button-style.css'
import {Layout} from "./components/Layout"
import {NoWallet} from "./components/NoWallet";
import {createIntl, createIntlCache, IntlProvider} from "react-intl";
import messages_en from './i18n/en.json';
import messages_zh from './i18n/zh.json';
import messages_ru from './i18n/ru.json';
import messages_id from './i18n/id.json';
import messages_ja from './i18n/ja.json';
import messages_ko from './i18n/ko.json';
import {getParam, testLocalization_} from "./util/util";

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

OrchidAPI.shared().init().then((walletStatus) => {
  render(
    <IntlProvider locale={language} messages={messages[language]}>
      <App walletStatus={walletStatus}/>
    </IntlProvider>,
    document.getElementById('root')
  );
});

const App: FC<{ walletStatus: WalletStatus }> = (props) => {
  const [walletStatus, setWalletStatus] = useState(props.walletStatus);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletStatusSub = api.walletStatus.subscribe(walletStatus => {
      console.log("wallet status: ", WalletStatus[walletStatus]);
      setWalletStatus(walletStatus);
    });
    return () => {
      walletStatusSub.unsubscribe();
    };
  }, []);

  let el: any;
  switch (walletStatus) {
    case WalletStatus.NoWallet:
    case WalletStatus.Error:
    case WalletStatus.WrongNetwork:
      el = <NoWallet walletStatus={walletStatus}/>;
      break;
    case WalletStatus.NotConnected:
    case WalletStatus.Connected:
      el = <Layout walletStatus={walletStatus}/>;
      break;
  }
  return el;
};


