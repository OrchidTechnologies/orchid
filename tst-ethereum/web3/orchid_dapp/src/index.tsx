import React, {FC} from 'react'
import ReactDOM from 'react-dom'
import {OrchidAPI} from "./api/orchid-api";

import 'bootstrap/dist/css/bootstrap.css'
import './index.css'
import './css/app-style.css'
import './css/button-style.css'
import {Layout} from "./components/Layout"

// const Layout: FC = () => {
//   const isMobile = useMediaQuery({query: '(max-width: 500px)'});
//   return isMobile ? <LayoutMobile/> : <LayoutDesktop/>;
// };

const NoWallet: FC = () => {
  return <h1>Not a dapp browser!</h1>;
};

OrchidAPI.shared().init().then((ok) => {
  ReactDOM.render(
    ok ? <Layout/> : <NoWallet/>,
    document.getElementById('root'));
});
