import React, {FC, useContext, useEffect, useState} from "react";
import {
  Button,
  Col,
  Container,
  Image,
  ListGroup,
  ListGroupItem,
  Nav,
  Navbar,
  OverlayTrigger,
  Popover,
  Row
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

export const Layout: FC<{ walletStatus: WalletStatus }> = (props) => {

  const [route, setRoute] = useState(pathToRoute(hashPath()) || Route.Overview);
  const [navEnabledState, setNavEnabledState] = useState(true);
  const [isNewUser, setIsNewUser] = useState(true);
  const [orchidTransactions, setOrchidTransactions] = useState<OrchidTransactionDetail[]>([]);

  const moreMenuItems = new Map<Route, string>([
    [Route.Balances, "Info"],
    [Route.Transactions, "Transactions"],
    [Route.MoveFunds, "Move Funds"],
    [Route.LockFunds, "Lock / Unlock Funds"],
    [Route.DebugPanel, "Advanced"]
  ]);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let newUserSub = api.newUser_wait.subscribe(isNew => {
      // Disable general nav for new user with no accounts.
      setIsNewUser(isNew);
      setNavEnabledState(!isNew);
    });
    let orchidTransactionsSub = api.orchid_transactions_wait.subscribe(txs => {
      // avoid some logging
      if (orchidTransactions.length === 0 && txs.length === 0) { return; }
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
        setNavEnabledState(enabled)
      },
      setRoute: (route:Route)=>{ setURL(route); setRoute(route); }
    }}>
      <Container className="main-content">
        <Row>
          <Col>
            <Header/>
            <Divider/>
            <Navbar className={navEnabled ? "" : "disabled-faded"}>
              <NavButton route={Route.Overview} icon={homeIcon} iconSelected={homeIconSelected}>Overview </NavButton>
              <NavButton route={Route.AddFunds} icon={addIcon} iconSelected={addIconSelected}>Add </NavButton>
              <NavButton route={Route.WithdrawFunds} icon={withdrawIcon} iconSelected={withdrawIconSelected}>Withdraw </NavButton>
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
                      <Nav.Link className={moreItemsSelected ? "selected" : ""}>More</Nav.Link>
                  </Button>
                </OverlayTrigger>
            </Navbar>
            <Divider/>
          </Col>
        </Row>
        {bannerTransactions}
        <Row className="page-content">
          <Col>
            <Visibility visible={route === Route.Overview}><Overview/></Visibility>
            <Visibility visible={route === Route.Balances}><Info/></Visibility>
            <Visibility visible={route === Route.AddFunds || route === Route.CreateAccount}>
              <AddFunds createAccount={route === Route.CreateAccount || isNewUser}/></Visibility>
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


