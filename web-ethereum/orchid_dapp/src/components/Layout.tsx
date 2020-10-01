import React, {FC, useContext, useEffect, useState} from "react";
import {
  Button, Col, Container, Image, ListGroup, ListGroupItem,
  Nav, Navbar, OverlayTrigger, Popover, Row
} from "react-bootstrap";
import {Transactions} from "./Transactions";
import {AddFunds} from "./AddFunds";
import {WithdrawFunds} from "./WithdrawFunds";
import {Info} from "./Info";
import {DebugPanel} from "./DebugPanel";
import {MoveFunds} from "./MoveFunds";
import {LockFunds} from "./LockFunds";
import {Header} from "./Header";
import './Layout.css'

import moreIcon from '../assets/more-outlined.svg'
import moreIconSelected from '../assets/more.svg'
import homeIcon from '../assets/overview-outlined.svg'
import homeIconSelected from '../assets/overview.svg'
import addIcon from '../assets/add-outlined.svg'
import addIconSelected from '../assets/add.svg'
import withdrawIcon from '../assets/withdraw-outlined.svg'
import withdrawIconSelected from '../assets/withdraw.svg'
import {Divider, hashPath, Visibility} from "../util/util";
import {OrchidAPI, WalletStatus} from "../api/orchid-api";
import {pathToRoute, Route, RouteContext, setURL} from "./Route";
import {Overview} from "./overview/Overview";
import {TransactionPanel} from "./TransactionPanel";
import {OrchidTransactionDetail} from "../api/orchid-tx";
import {S} from "../i18n/S";
import {StakeFunds} from "./StakeFunds";
import {MarketConditionsPanel} from "./MarketConditionsPanel";
import {LowFundsPanel} from "./LowFundsPanel";

export const Layout: FC<{ walletStatus: WalletStatus }> = (props) => {

  const [route, setRoute] = useState<Route>(pathToRoute(hashPath()) ?? Route.None);
  const [navEnabledState, setNavEnabledState] = useState(true);
  const [isNewUser, setIsNewUser] = useState(true);
  const [orchidTransactions, setOrchidTransactions] = useState<OrchidTransactionDetail[]>([]);

  const moreMenuItems = new Map<Route, string>([
    [Route.Balances, S.info],
    [Route.Transactions, S.transactions],
    [Route.MoveFunds, S.moveFunds],
    [Route.LockFunds, S.lockUnlockFunds],
    [Route.DebugPanel, S.advanced]
  ]);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let newUserSub = api.newUser_wait.subscribe(isNew => {
      setIsNewUser(isNew);
      if (route === Route.None) {
        setRoute(isNew ? Route.CreateAccount : Route.AddFunds)
      }
    });
    let orchidTransactionsSub = api.orchid_transactions_wait.subscribe(txs => {
      setOrchidTransactions(txs);
    });
    return () => {
      newUserSub.unsubscribe();
      orchidTransactionsSub.unsubscribe();
    };
  }, []);

  let bannerTransactions = orchidTransactions.map(orcTx => {
    return (<Row key={orcTx.hash}><TransactionPanel tx={orcTx}/></Row>);
  });

  // @formatter:off
  let moreItemsSelected = Array.from(moreMenuItems.keys()).includes(route);
  let navEnabled = navEnabledState && props.walletStatus === WalletStatus.Connected;
  return (
    <RouteContext.Provider value={{
      route: route,
      setNavEnabled: (enabled: boolean) => {
        console.log("set nav enabled: ", enabled);
        //setNavEnabledState(enabled)
      },
      setRoute: (route:Route)=>{ setURL(route); setRoute(route); }
    }}>
      <Container className="main-content">
        <Row>
          <Col>
            <Header/>
            <Divider/>
            <Navbar className={navEnabled ? "" : "disabled-faded"}>
              <NavButton route={Route.Overview} icon={homeIcon} iconSelected={homeIconSelected}>{S.overview}</NavButton>
              <NavButton route={Route.AddFunds} icon={addIcon} iconSelected={addIconSelected}>{S.add}</NavButton>
              <NavButton route={Route.WithdrawFunds} icon={withdrawIcon} iconSelected={withdrawIconSelected}>{S.withdraw}</NavButton>
                <OverlayTrigger
                  rootClose={true} trigger="click" placement='bottom'
                  overlay={
                    <Popover id='moreitems-popover'>

                      <Popover.Content onClick={()=>document.body.click()}>
                        <ListGroup variant="flush">{
                          Array.from(moreMenuItems.entries()).map(([key,value])=>{
                              return <ListGroupItem key={key}><NavRow route={key}>{value}</NavRow></ListGroupItem>
                            })
                          }</ListGroup>
                      </Popover.Content>
                    </Popover>
                  }>
                  <Button className={"Layout-nav-button "}>
                      <Image src={moreItemsSelected ? moreIconSelected : moreIcon}/>
                      <Nav.Link className={moreItemsSelected ? "selected" : ""}>{S.more}</Nav.Link>
                  </Button>
                </OverlayTrigger>
            </Navbar>
            <Divider/>
          </Col>
        </Row>
        <Row><MarketConditionsPanel/></Row>
        <Row><LowFundsPanel/></Row>
        {bannerTransactions}
        <Row className="page-content">
          <Col>
            <Visibility visible={route === Route.Overview}><Overview/></Visibility>
            <Visibility visible={route === Route.Balances}><Info/></Visibility>
            <Visibility visible={route === Route.AddFunds || route === Route.CreateAccount}>
              <AddFunds
                // Recreate this component's state for the add and create usages
                key={(route === Route.CreateAccount || isNewUser).toString()}
                createAccount={route === Route.CreateAccount || isNewUser}/></Visibility>
            <Visibility visible={route === Route.StakeFundsTest}><StakeFunds/></Visibility>
            <Visibility visible={route === Route.WithdrawFunds}><WithdrawFunds/></Visibility>
            <Visibility visible={route === Route.Transactions}><Transactions/></Visibility>
            <Visibility visible={route === Route.MoveFunds}><MoveFunds/></Visibility>
            <Visibility visible={route === Route.LockFunds}><LockFunds/></Visibility>
            <Visibility visible={route === Route.DebugPanel}><DebugPanel/></Visibility>
          </Col>
        </Row>
        {/*<Divider/>*/}
      </Container>
    </RouteContext.Provider>
  );
  // @formatter:on
};

const NavButton: FC<{ route: Route, icon: any, iconSelected: any }> = (props) => {
  let {route, setRoute} = useContext(RouteContext);
  let selected = route === props.route;
  let showIcon = selected ? props.iconSelected : props.icon;
  return (
    <Nav className="Layout-nav-button"
         onClick={() => setRoute(props.route)}>
      <Image src={showIcon}/>
      <Nav.Link className={selected ? "selected" : ""}>{props.children}</Nav.Link>
    </Nav>
  );
};

const NavRow: FC<{ route: Route }> = (props) => {
  let {route, setRoute} = useContext(RouteContext);
  let selected = route === props.route;
  return (
    <Nav.Link
      className={"Layout-nav-row " + (selected ? "selected" : "")}
      onClick={() => setRoute(props.route)}>
      {props.children}
    </Nav.Link>
  );
};


