import React, {useContext} from "react";
import {Col, Row} from "react-bootstrap";
import {SubmitButton} from "../SubmitButton";
import {Route, RouteContext} from "../Route";
import './Overview.css';
import beaver from '../../assets/beaver1.svg';
import {OverviewProps} from "./Overview";
import {S} from "../../i18n/S";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const OverviewDefault: React.FC<OverviewProps> = (props) => {
  let {setRoute} = useContext(RouteContext);
  let {noAccount, potFunded, walletEthEmpty, walletOxtEmpty} = props;

  let instructions: string;
  if (potFunded) {
    instructions = S.yourOrchidAccountIsFunded;
  } else if (walletEthEmpty && walletOxtEmpty) {
    instructions = S.yourWalletIsEmpty + "  " + S.transferOXTandEnoughETH;
  } else if (walletEthEmpty) {
    instructions =
      S.yourWalletETHbalanceIsEmpty + "  " + S.transferEnoughETHtoCoverTwo;
  } else if (walletOxtEmpty) {
    instructions = S.yourWalletOXTbalanceIsEmpty + "  " + S.transferOXTToThisDappWallet;
  } else if (noAccount) {
    instructions = S.youAreReadyToCreateOrchidAccount + "  " + S.continueBelowToCreateAccount;
  } else {
    // You have an existing account but it has no OXT.
    instructions = S.yourOrchidAccountIsReadyToReceive + "  " + S.proceedBelowToAddFunds;
  }

  return (
    <div>
      <div className="Overview-box">
        <Row><Col>
          <div className="Overview-title">{S.welcomeToYourOrchidAccount}</div>
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
        {noAccount ? S.createAccount : S.addFundsToYourAccount}
      </SubmitButton>
    </div>
  );
};

