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
import {Signer} from "../api/orchid-eth";
import {Route, RouteContext} from "./RouteContext";
import {S} from "../i18n/S";
import {Subscription} from "rxjs";
import {WalletProviderState} from "../api/orchid-eth-web3";
import {LotFunds} from "../api/orchid-eth-token-types";
import {AccountContext, WalletProviderContext} from "../index";
import {ChainInfo} from "../api/chains/chains";

export const Header: React.FC = () => {
  const [newUser, setNewUser] = useState<boolean | undefined>(undefined);
  const [signers, setSigners] = useState<Signer[] | null>(null);
  const [connecting, setConnecting] = useState(false);

  let pot = useContext(AccountContext);
  let fundsBalance = pot?.balance;
  let walletStatus = useContext(WalletProviderContext);
  //let {fundsToken, gasToken} = walletStatus;

  useEffect(() => {
    let subscriptions: Subscription [] = [];
    let api = OrchidAPI.shared();
    subscriptions.push(api.newUser.subscribe(setNewUser));
    subscriptions.push(api.signersAvailable.subscribe(setSigners));
    return () => {
      subscriptions.forEach(sub => {
        sub.unsubscribe()
      })
    };
  }, []);

  let showAccountSelector = !newUser && fundsBalance;
  //if (walletStatus) { console.log("header: wallet connection status: ", WalletProviderState[walletStatus.state], walletStatus.account); }
  let showConnectButton = !showAccountSelector
    //&& (walletStatus?.state === WalletProviderState.NoWalletProvider || walletStatus?.state === WalletProviderState.NotConnected)
    && (walletStatus?.state === WalletProviderState.NoWalletProvider);
  let showNewAccount = !showAccountSelector && walletStatus.state === WalletProviderState.Connected;
  return (
    <Container>
      <Row noGutters={true} style={{marginBottom: '14px'}}>

        {/*Logo*/}
        <Col>
          <img style={{width: '130px', height: '56px', marginBottom: '16px'}}
               src={logo} alt="Orchid Account"/>
        </Col>

        {/*right column*/}
        <Col style={{textAlign: "right"}}>
          <Row noGutters={true} style={{display: "block"}}>
            {/*Account / Balance*/}
            {
              showAccountSelector ?
                <AccountSelector
                  signers={signers || []}
                  fundsBalance={fundsBalance ?? null}
                  chainInfo={walletStatus.chainInfo}
                /> : null
            }
            {
              showNewAccount ? <span>New Account</span> : null
            }
            {
              showConnectButton ?
                <ConnectButton disabled={connecting} onClick={() => {
                  setConnecting(true);
                  OrchidAPI.shared().provider.connect(true).finally(() => {
                    setConnecting(false);
                  });
                }}/>
                : null
            }
          </Row>

          {/*show chain info*/}
          <Row noGutters={true} style={{display: "block"}}>
              <span style={{fontSize: 12, marginTop: 8}}>
                {walletStatus.chainInfo?.name ?? ""}
              </span>
          </Row>
        </Col>
      </Row>
    </Container>
  );
};

function AccountSelector(props: {
  signers: Signer [], fundsBalance: LotFunds | null, chainInfo: ChainInfo | null
}) {
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
                  OrchidAPI.shared().provider.disconnect()
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
        {/*<span style={{display: "block", fontSize: 12, marginTop: 4}}>{props.chainInfo?.name ?? ""}</span>*/}
      </div>
    </OverlayTrigger>
  );
}

function AccountBalance(props: { fundsBalance: LotFunds | null }) {
  return (
    <Row noGutters={true}>
      <Col style={{flexGrow: 2}}>
        <Row noGutters={true}>
          <Col>
            <div className="header-balance">{S.balanceCaps}</div>
            <div className="header-balance-value">{props.fundsBalance?.formatCurrency() ?? ""}</div>
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
