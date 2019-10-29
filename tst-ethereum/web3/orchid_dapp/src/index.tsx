import React, {FC} from 'react'
import ReactDOM from 'react-dom'
import {OrchidAPI} from "./api/orchid-api";

import 'bootstrap/dist/css/bootstrap.css'
import './index.css'
import './css/app-style.css'
import './css/form-style.css'
import './css/button-style.css'
import {Layout} from "./components/Layout"
import {ok} from "assert";

OrchidAPI.shared().init().then((status) => {
  ReactDOM.render(
    ok ? <Layout status={status}/> : <NoWallet/>,
    document.getElementById('root'));
});

const NoWallet: FC = () => {
  return <h1>Not a dapp browser!</h1>;
};

