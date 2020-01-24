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

OrchidAPI.shared().init().then((walletStatus) => {
  render(<App walletStatus={walletStatus}/>, document.getElementById('root'));
});

const App: FC<{walletStatus: WalletStatus}> = (props) => {
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
  switch(walletStatus) {
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


