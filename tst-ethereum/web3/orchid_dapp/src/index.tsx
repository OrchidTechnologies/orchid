import React from 'react'
import {render} from 'react-dom'
import {OrchidAPI, WalletStatus} from "./api/orchid-api";

import 'bootstrap/dist/css/bootstrap.css'
import './index.css'
import './css/app-style.css'
import './css/form-style.css'
import './css/button-style.css'
import {Layout} from "./components/Layout"
import {NoWallet} from "./components/NoWallet";

OrchidAPI.shared().init().then((status) => {
  let el: any;
  switch(status) {
    case WalletStatus.NoWallet:
    case WalletStatus.Error:
      el = <NoWallet/>;
      break;
    case WalletStatus.NotConnected:
    case WalletStatus.Connected:
      el = <Layout status={status}/>;
      break;
  }
  render(el, document.getElementById('root'));
});


