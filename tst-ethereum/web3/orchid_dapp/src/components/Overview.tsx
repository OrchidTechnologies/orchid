import React, {useContext, useEffect, useState} from "react";
import './DebugPanel.css'
import {Col, Row} from "react-bootstrap";
import {SubmitButton} from "./SubmitButton";
import {Route, RouteContext} from "./Route";
import './Overview.css';
import beaver from '../assets/beaver1.svg';
import coinbase from '../assets/coinbase.jpg';
import {hashPath} from "../util/util";
import {OrchidAPI, WalletStatus} from "../api/orchid-api";
import {oxtToWei} from "../api/orchid-eth";

export const Overview: React.FC = () => {
  const [initialPath] = useState(hashPath());
  if (initialPath === "#earn") {
    return <OverviewEarn/>;
  } else {
    return <OverviewDefault/>;
  }
};

const OverviewDefault: React.FC = () => {
  let {setRoute} = useContext(RouteContext);
  return (
    <div>
      <div className="Overview-box">
        <Row><Col>
          <div className="Overview-title">Welcome to your Orchid Account</div>
        </Col></Row>
        <Row style={{marginTop: '24px'}} noGutters={true}>
          <Col className="Overview-copy">
            Add, move, withdraw and connect funds here for use in the Orchid App. Your Orchid
            Account is linked to the wallet you first associate it with.
          </Col>
          <Col>
            <img style={{width: '82px', height: '92px', marginRight: '30px', marginBottom: '24px'}}
                 src={beaver} alt="Beaver"/>
          </Col>
        </Row>
      </div>
      <div className="Overview-bottomText">
        Ready to start using the Orchid App? Use our suggested funding amounts and quick fund:
      </div>
      <SubmitButton onClick={() => {
        setRoute(Route.AddFunds)
      }} enabled={true}>
        Add Funds to your Account
      </SubmitButton>
    </div>
  );
};

const OverviewEarn: React.FC = () => {
  let {setRoute, setNavEnabled} = useContext(RouteContext);
  const [walletEthEmpty, setWalletEthEmpty] = useState(false);
  const [walletOxtEmpty, setWalletOxtEmpty] = useState();
  const [potFunded, setPotFunded] = useState(false);
  const earnTargetAmountOXT = oxtToWei(20.0);
  const earnTargetDepositOXT = oxtToWei(10.0);

  useEffect(() => {
    setNavEnabled(false);
    let api = OrchidAPI.shared();
    let subscription = api.lotteryPot_wait.subscribe(pot => {
      setPotFunded(pot.balance >= earnTargetAmountOXT && pot.escrow >= earnTargetDepositOXT);
      setWalletOxtEmpty(pot.account.oxtBalance <= BigInt(0));
      setWalletEthEmpty(pot.account.ethBalance <= BigInt(0));
    });
    return () => {
      subscription.unsubscribe();
    };
  }, []);

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
            <img style={{width: '60%', marginBottom: '24px'}} src={coinbase} alt="Coinbase"/>
          </Col>
        </Row>
      </div>
      <div className="Overview-bottomText">
        {
          (()=>{
            // if (potFunded)
            // if (walletEthEmpty) {
              return "Your Orchid Account is ready to receive funds from your wallet. " +
                "Continue below to finalize funding your account.";
            // }
          })()
        }
      </div>
      <SubmitButton onClick={() => {
        setNavEnabled(true);
        setRoute(Route.AddFunds)
      }} enabled={!walletEthEmpty && !potFunded}>
        Add Funds to your Account
      </SubmitButton>
    </div>
  );
};

