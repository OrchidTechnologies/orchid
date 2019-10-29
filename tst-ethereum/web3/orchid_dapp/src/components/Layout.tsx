import React, {FC, useContext, useState} from "react";
import {
  Button, Col, Container, Image, ListGroup, ListGroupItem, Nav, Navbar, OverlayTrigger, Popover, Row
} from "react-bootstrap";
import Header from "./Header";
import {Transactions} from "./Transactions";
import {AddFunds} from "./AddFunds";
import {WithdrawFunds} from "./WithdrawFunds";
import {Balances} from "./Balances";
import {DebugPanel} from "./DebugPanel";
import {MoveFunds} from "./MoveFunds";
import {LockFunds} from "./LockFunds";
import {ManageKeys} from "./ManageKeys";
import './Layout.css'

import moreIcon from '../assets/more-outlined.svg'
import moreIconSelected from '../assets/more.svg'
import homeIcon from '../assets/overview-outlined.svg'
import homeIconSelected from '../assets/overview.svg'
import addIcon from '../assets/add-outlined.svg'
import addIconSelected from '../assets/add.svg'
import withdrawIcon from '../assets/withdraw-outlined.svg'
import withdrawIconSelected from '../assets/withdraw.svg'
import {Divider, Visibility} from "../util/util";
import {WalletStatus} from "../api/orchid-api";
import {Overview} from "./Overview";
import {Route, RouteContext} from "./Route";

export const Layout: FC<{ status: WalletStatus }> = (props) => {
  const [route, setRoute] = useState(Route.Overview);
  const moreMenuItems = new Map<Route, string>([
    [Route.Balances, "Balances"],
    [Route.Transactions, "Transactions"],
    [Route.MoveFunds, "Move Funds"],
    [Route.LockFunds, "Lock / Unlock Funds"],
    [Route.ManageKeys, "Manage Keys"],
    [Route.DebugPanel, "Debug Panel"]
  ]);

  // @formatter:off
  let moreItemsSelected = Array.from(moreMenuItems.keys()).includes(route);
  let navEnabled = props.status === WalletStatus.Connected;
  return (
    <RouteContext.Provider value={{route: route, setRoute: setRoute}}>
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
        <Row className="page-content">
          <Col>
            <Visibility visible={route === Route.Overview}><Overview/></Visibility>
            <Visibility visible={route === Route.Balances}><Balances/></Visibility>
            <Visibility visible={route === Route.AddFunds}><AddFunds/></Visibility>
            <Visibility visible={route === Route.WithdrawFunds}><WithdrawFunds/></Visibility>
            <Visibility visible={route === Route.Transactions}><Transactions/></Visibility>
            <Visibility visible={route === Route.MoveFunds}><MoveFunds/></Visibility>
            <Visibility visible={route === Route.LockFunds}><LockFunds/></Visibility>
            <Visibility visible={route === Route.ManageKeys}><ManageKeys/></Visibility>
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

const NavRow: FC<{ route: Route}> = (props) => {
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


