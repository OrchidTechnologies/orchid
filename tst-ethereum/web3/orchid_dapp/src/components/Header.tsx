import React from "react";
import logo from '../assets/name_logo.png'
import wallet from '../assets/wallet.png'

const Header: React.FC = () => {
  return (
    <div>
      <div style={{width: '262px', height: '50px'}}>
        <img style={{height: '40px'}} src={logo} alt=""/>
        <img style={{height: '38px', marginLeft: '8px'}} src={wallet} alt=""/>
      </div>
    </div>
  );
};

export default Header;
