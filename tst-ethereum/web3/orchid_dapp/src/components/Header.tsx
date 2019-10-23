import React from "react";
import logo from '../assets/name_logo.png'

const Header: React.FC = () => {
  return (
    <div>
      <div style={{marginBottom: '8px', marginLeft: '8px'}}>
        <img style={{
          width: '130px',
          height: '33px',
        }} src={logo} alt=""/>
        <span style={{
          display: "block",
          fontFamily: 'Noto Sans',
          letterSpacing: '0pt',
          fontSize: '17pt',
          color: 'rgb(95,69,186)',
          marginLeft: '6px',
          marginTop: '2px'
        }}>account</span>
      </div>
    </div>
  );
};

export default Header;
