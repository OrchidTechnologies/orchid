import React, {useContext} from "react";
import {Col, Row} from "react-bootstrap";
import {SubmitButton} from "../SubmitButton";
import {Route, RouteContext} from "../Route";
import './Overview.css';
import beaver from '../../assets/beaver1.svg';
import {OverviewProps} from "./Overview";
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const OverviewDefault: React.FC<OverviewProps> = (props) => {
  let {setRoute} = useContext(RouteContext);
  let {noAccount, potFunded, walletEthEmpty, walletOxtEmpty} = props;

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
    // You have an existing account but it has no OXT.
    instructions = "Your Orchid Account is ready to receive funds from your wallet. " +
      "Proceed to below to add funds to your account.";
  }

  return (
    <div>
      <div className="Overview-box">
        <Row><Col>
          <div className="Overview-title">Welcome to your Orchid Account</div>
        </Col></Row>
        <Row style={{marginTop: '24px'}} noGutters={true}>
          <Col className="Overview-copy">
            {instructions}
          </Col>
          <Col>
            <img style={{width: '82px', height: '92px', marginRight: '30px', marginBottom: '24px'}}
                 src={beaver} alt="Beaver"/>
          </Col>
        </Row>
      </div>
      <div className="Overview-bottomText">
      </div>
      <SubmitButton
        onClick={() => {
          setRoute(noAccount ? Route.CreateAccount : Route.AddFunds)
        }}
        hidden={potFunded}
        enabled={!potFunded && !walletOxtEmpty && !walletEthEmpty}>
        {noAccount ? "Create Account" : "Add Funds to your Account"}
      </SubmitButton>
    </div>
  );
};

