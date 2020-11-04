import React, {useContext, useEffect, useState} from "react";
import logo from '../assets/name-logo.svg'
import tokenLogo from '../assets/orchid-token-purple.svg'
import {
  Col,
  Container,
  ListGroup,
  ListGroupItem,
  OverlayTrigger,
  Popover,
  Row
} from "react-bootstrap";
import './Header.css';
import {OrchidAPI} from "../api/orchid-api";
import {keikiToOxtString, Signer} from "../api/orchid-eth";
import {Route, RouteContext} from "./Route";
import {S} from "../i18n/S";
import {Subscription} from "rxjs";
import {WalletProviderState, WalletProviderStatus} from "../api/orchid-eth-web3";

export const Header: React.FC = () => {
  const [oxtBalance, setOxtBalance] = useState<string | null>(null);
  const [newUser, setNewUser] = useState<boolean | undefined>(undefined);
  const [signers, setSigners] = useState<Signer[] | null>(null);
  const [walletStatus, setWalletStatus] = useState<WalletProviderStatus | undefined>(undefined);
  const [connecting, setConnecting] = useState(false);

  useEffect(() => {
    let subscriptions: Subscription [] = [];
    let api = OrchidAPI.shared();
    subscriptions.push(api.newUser.subscribe(setNewUser));
    subscriptions.push(api.signersAvailable.subscribe(setSigners));
    subscriptions.push(api.lotteryPot.subscribe(pot => {
      if (pot) {
        setOxtBalance(keikiToOxtString(pot.balance, 2));
      } else {
        setOxtBalance(null);
      }
    }));
    subscriptions.push(api.eth.provider.walletStatus.subscribe(setWalletStatus));
    return () => {
      subscriptions.forEach(sub => {
        sub.unsubscribe()
      })
    };
  }, []);

  let showAccountSelector = !newUser && !(oxtBalance == null);
  //if (walletStatus) { console.log("header: wallet connection status: ", WalletProviderState[walletStatus.state], walletStatus.account); }
  let showConnectButton = !showAccountSelector
    //&& (walletStatus?.state === WalletProviderState.NoWalletProvider || walletStatus?.state === WalletProviderState.NotConnected)
    && (walletStatus?.state === WalletProviderState.NoWalletProvider)
  return (
    <Container>
      <Row noGutters={true} style={{marginBottom: '14px'}}>

        {/*Logo*/}
        <Col>
          <img style={{width: '130px', height: '56px', marginBottom: '16px'}}
               src={logo} alt="Orchid Account"/>
        </Col>

        {/*Account / Balance*/}
        {
          showAccountSelector ?
            <AccountSelector signers={signers || []} oxtBalance={oxtBalance || ""}/> : null
        }
        {
          showConnectButton ?
            <ConnectButton disabled={connecting} onClick={() => {
              setConnecting(true);
              OrchidAPI.shared().eth.provider.connect(true).finally( ()=>{
                  setConnecting(false);
              });
            }}/>
            : null
        }
        {
          (walletStatus?.state === WalletProviderState.Connected && !walletStatus?.isMainNet()) ?
            <div style={{width: 200, fontStyle: 'italic', fontSize: 14, textAlign: 'right'}}>
            Please connect to<br/>Ethereum Main Net</div> : null
        }

      </Row>
    </Container>
  );
};

function AccountSelector(props: { signers: Signer [], oxtBalance: string }) {
  let {setRoute} = useContext(RouteContext);
  return (
    <OverlayTrigger
      rootClose={true} trigger="click" placement='bottom'
      overlay={
        <Popover id='account-selector-popover'>
          {/*<PopoverTitle style={{textAlign: 'center'}}>Select Account</PopoverTitle>*/}
          <Popover.Content onClick={() => document.body.click()}>
            <ListGroup variant="flush">
              {
                props.signers.map((signer: Signer) => {
                  let len = signer.address.length;
                  let address = signer.address.substring(0, 4) + "..." + signer.address.substring(len - 5, len);
                  return <ListGroupItem
                    onClick={() => {
                      let api = OrchidAPI.shared();
                      let wallet = api.wallet.value;
                      if (!wallet) {
                        return;
                      }
                      console.log("Account selector chose signer: ", signer.address);
                      api.signer.next(new Signer(wallet, signer.address))
                    }}
                    key={signer.address}>
                    <span style={{fontWeight: 'bold'}}>{S.account}: </span><span
                    style={{fontFamily: 'Monospace'}}>{address}</span>
                  </ListGroupItem>
                })
              }
              <ListGroupItem
                onClick={() => {
                  setRoute(Route.CreateAccount);
                }}
                key={"new-item"}
                style={{
                  fontWeight: 'bold',
                  backgroundColor: 'transparent'
                }}>
                <span>{S.createNewAccount}</span>
              </ListGroupItem>
              <ListGroupItem
                onClick={() => {
                  // disconnect
                  OrchidAPI.shared().eth.provider.disconnect()
                }}
                key={"disconnect-item"}
                style={{
                  fontWeight: 'bold',
                  backgroundColor: 'transparent'
                }}>
                <span>{"Disconnect"}</span>
              </ListGroupItem>
            </ListGroup>
          </Popover.Content>
        </Popover>
      }>
      <div>
        <AccountBalance {...props}/>
      </div>
    </OverlayTrigger>
  );
}

function AccountBalance(props: { oxtBalance: string }) {
  return (
    <Row>
      <Col style={{flexGrow: 2}}>
        <Row noGutters={true}>
          <Col>
            <div className="header-balance">{S.balanceCaps}</div>
            <div className="header-balance-value">{props.oxtBalance || ""} OXT</div>
          </Col>
          <Col style={{flexGrow: 0}}>
            <img style={{
              display: "block",
              marginTop: "6px",
              marginLeft: "8px",
              width: "24px", height: "24px"
            }} src={tokenLogo} alt="Orchid Account"/>
          </Col>
        </Row>
      </Col>
    </Row>
  );
}
function ConnectButton(props: { disabled: boolean, onClick: () => void }) {
  return <div className={"submit-button"}>
    <button
      disabled={props.disabled}
      onClick={props.onClick}>
      <span>{"Connect Wallet"}</span>
    </button>
  </div>;
}

