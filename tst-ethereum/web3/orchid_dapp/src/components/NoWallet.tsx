import React, {FC, useState} from "react";
import {Container} from "react-bootstrap";
import './NoWallet.css';
import bugs from '../assets/bugs.png';
import {SubmitButton} from "./SubmitButton";
import {WalletStatus} from "../api/orchid-api";

export const NoWallet: FC<{ walletStatus: WalletStatus }> = (props) => {
  const [buttonCopiedState, setButtonCopiedState] = useState(false);

  function copyUrl() {
    // https://stackoverflow.com/questions/49618618/copy-current-url-to-clipboard
    let dummy = document.createElement('input');
    let text = window.location.href;
    document.body.appendChild(dummy);
    dummy.value = text;
    dummy.select();
    document.execCommand('copy');
    document.body.removeChild(dummy);

    // Show copied message in the button
    setButtonCopiedState(true);
    setTimeout(() => {
      setButtonCopiedState(false);
    }, 1000);
  }

  let wrongNetwork = props.walletStatus === WalletStatus.WrongNetwork;
  return (
    <Container className="NoWallet" style={{textAlign: 'center'}}>
      <div className="NoWallet-title">You’re almost there!</div>
      <div className="NoWallet-text"> {
          wrongNetwork ?
            "Please select the Ethereum Main Network in your Dapp Browser!"
            : "Paste this URL in a DApp browser (crypto wallet browser) to connect."
      } </div>
      <img className="NoWallet-image" src={bugs} alt="Bugs"/>
      <div style={{marginTop: '16px'}}>
        <SubmitButton
          hidden={wrongNetwork}
          onClick={copyUrl}
          enabled={true}>
          {buttonCopiedState ? "Copied!" : "Copy URL"}
        </SubmitButton>
      </div>
    </Container>
  )
};
