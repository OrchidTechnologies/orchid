import React, {useContext, useEffect, useState} from "react";
import './DebugPanel.css'
import {Col, Row} from "react-bootstrap";
import {SubmitButton} from "./SubmitButton";
import {Route, RouteContext} from "./Route";
import './Overview.css';
import beaver from '../assets/beaver1.svg';
import coinbase from '../assets/coinbase.jpg';
import {hashPath} from "../util/util";
import {OrchidAPI} from "../api/orchid-api";
import {oxtToWei} from "../api/orchid-eth";

interface OverviewProps {
  walletEthEmpty?: boolean
  walletOxtEmpty?: boolean
  potFunded?: boolean
  earnTargetAmountOXT: BigInt
  earnTargetDepositOXT: BigInt
}

export const Overview: React.FC = () => {
  const [walletEthEmpty, setWalletEthEmpty] = useState(undefined as boolean|undefined);
  const [walletOxtEmpty, setWalletOxtEmpty] = useState(undefined as boolean|undefined);
  const [potFunded, setPotFunded] = useState(undefined as boolean|undefined);
  // const earnTargetAmountOXT = oxtToWei(20.0);
  // const earnTargetDepositOXT = oxtToWei(10.0);
  const earnTargetAmountOXT = BigInt(1); // allow anything greater than zero
  const earnTargetDepositOXT = BigInt(1);

  useEffect(() => {
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

  let props: OverviewProps = {
    walletEthEmpty: walletEthEmpty,
    walletOxtEmpty: walletOxtEmpty,
    potFunded: potFunded,
    earnTargetAmountOXT: earnTargetDepositOXT,
    earnTargetDepositOXT: earnTargetDepositOXT
  };

  const [initialPath] = useState(hashPath());

  if (potFunded === undefined) {
    return <OverviewLoading/>
  }

  if (initialPath === "#earn") {
    return <OverviewEarn {...props}/>;
  } else {
    return <OverviewDefault {...props}/>;
  }
};

const OverviewDefault: React.FC<OverviewProps> = (props) => {
  let {setRoute} = useContext(RouteContext);
  let {potFunded, walletEthEmpty, walletOxtEmpty} = props;

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
  } else {
    instructions = "Your Orchid Account is ready to receive funds from your wallet. " +
      "Continue below to finalize funding your account.";
  }

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
        {instructions}
      </div>
      <SubmitButton
        onClick={() => { setRoute(Route.AddFunds) }}
        hidden={potFunded}
        enabled={!potFunded && !walletOxtEmpty && !walletEthEmpty}>
        Add Funds to your Account
      </SubmitButton>
    </div>
  );
};

const OverviewEarn: React.FC<OverviewProps> = (props) => {
  let {setRoute, setNavEnabled} = useContext(RouteContext);
  let {potFunded, walletEthEmpty, walletOxtEmpty} = props;

  useEffect(() => {
    setNavEnabled(false);
  }, []);

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
        onClick={() => { setNavEnabled(true); setRoute(Route.AddFunds) }}
        enabled={!potFunded && !walletOxtEmpty && !walletEthEmpty}
        hidden={potFunded}>
        Add Funds to your Account
      </SubmitButton>
    </div>
  );
};

const OverviewLoading: React.FC = () => {
  return <div style={{textAlign: 'center', marginTop: '24px'}}>Checking Wallet Status...</div>
};
