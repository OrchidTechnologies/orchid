import React, {useContext} from "react";
import {Col, Row} from "react-bootstrap";
import {SubmitButton} from "../SubmitButton";
import {Route, RouteContext} from "../Route";
import './Overview.css';
import coinbase from '../../assets/coinbase.jpg';
import {OverviewProps} from "./Overview";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

// Note: This file duplicates some functionality of the default for future flexibility.
export const OverviewEarn: React.FC<OverviewProps> = (props) => {
  let {setRoute, setNavEnabled} = useContext(RouteContext);
  let {noAccount, potFunded, walletEthEmpty, walletOxtEmpty} = props;

  // currently duplicates above but this text may be customized
  let instructions: string;
  if (potFunded) {
    instructions = "Your Orchid Account is funded and ready to go!."
  } else if (walletEthEmpty && walletOxtEmpty) {
    instructions = "Your wallet is empty. " +
      "Transfer OXT and enough ETH to cover two transactions to this dapp wallet in order to continue.";
  } else if (walletEthEmpty) {
    instructions = "Your wallet ETH balance is empty. " +
      "Transfer enough ETH to cover two transactions to this dapp wallet in order to continue.";
  } else if (walletOxtEmpty) {
    instructions = "Your wallet OXT balance is empty. " +
      "Transfer OXT to this dapp wallet in order to continue.";
  } else if (noAccount) {
    instructions = "You are ready to create an Orchid account with funds from your wallet. " +
      "Continue below to create your account.";
  } else {
    instructions = "Your Orchid Account is ready to receive funds from your wallet. " +
      "Continue below to finalize funding your account.";
  }

  return (
    <div>
      <div className="Overview-box" style={{backgroundColor: 'rgb(247, 247, 247)'}}>
        <Row>
          <Col>
            <div className="Overview-title"
                 style={{marginLeft: 0, textAlign: 'center'}}>Welcome from Coinbase Earn
            </div>
          </Col>
        </Row>
        <Row style={{marginTop: '8px', textAlign: 'center'}} noGutters={true}>
          <Col>
            <img style={{width: '40%', marginBottom: '24px'}} src={coinbase} alt="Coinbase"/>
          </Col>
        </Row>
      </div>
      <div className="Overview-bottomText">
        {instructions}
      </div>
      <SubmitButton
        onClick={() => {
          setNavEnabled(true);
          setRoute(noAccount ? Route.CreateAccount : Route.AddFunds)
        }}
        enabled={!potFunded && !walletOxtEmpty && !walletEthEmpty}
        hidden={potFunded}>
        {noAccount ? "Create Account" : "Add Funds to your Account"}
      </SubmitButton>
    </div>
  );
};

