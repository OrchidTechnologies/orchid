import React, {useContext, useEffect, useState} from "react";
import logo from '../assets/name-logo.svg'
import tokenLogo from '../assets/orchid-token-purple.svg'
import {
  Col, Container, ListGroup, ListGroupItem, OverlayTrigger, Popover, Row
} from "react-bootstrap";
import './Header.css';
import {OrchidAPI} from "../api/orchid-api";
import {Signer, weiToOxtString} from "../api/orchid-eth";
import {Visibility} from "../util/util";
import {Route, RouteContext} from "./Route";

export const Header: React.FC = () => {
  const [oxtBalance, setOxtBalance] = useState<string | null>(null);
  const [newUser, setNewUser] = useState<boolean | undefined>(undefined);
  const [signers, setSigners] = useState<Signer[] | undefined>(undefined);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let newSub = api.newUser_wait.subscribe(setNewUser);
    let signersSub = api.signersAvailable_wait.subscribe(setSigners);
    let lotSub = api.lotteryPot_wait.subscribe(pot => {
      setOxtBalance(weiToOxtString(pot.balance, 2));
    });
    return () => {
      lotSub.unsubscribe();
      signersSub.unsubscribe();
      newSub.unsubscribe();
    };
  }, []);

  let show = !newUser && !(oxtBalance == null);
  return (
    <Container>
      <Row noGutters={true} style={{marginBottom: '14px'}}>

        {/*Logo*/}
        <Col>
          <img style={{width: '130px', height: '56px', marginBottom: '16px'}}
               src={logo} alt="Orchid Account"/>
        </Col>

        {/*Account / Balance*/}
        <Visibility visible={show}>
          <AccountSelector signers={signers || []} oxtBalance={oxtBalance || ""}/>
        </Visibility>
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
                let address = signer.address.substring(0,4)+"..."+signer.address.substring(len-5, len);
                return <ListGroupItem
                  onClick={() => {
                    let api = OrchidAPI.shared();
                    let wallet = api.wallet.value;
                    if (!wallet) { return; }
                    api.signer.next(new Signer(wallet, signer.address))
                  }}
                  key={signer.address}>
                  <span style={{fontWeight: 'bold'}}>Account: </span><span style={{fontFamily: 'Monospace'}}>{address}</span>
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
              <span >Create New Account</span>
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
            <div className="header-balance">BALANCE</div>
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
