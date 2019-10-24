import React, {Component, FC} from "react";
import {
  Button, Col, Container, Image, ListGroup, ListGroupItem, Nav, Navbar, OverlayTrigger, Popover, Row
} from "react-bootstrap";
import Header from "./Header";
import {Transactions} from "./Transactions";
import {AddFunds} from "./AddFunds";
import {WithdrawFunds} from "./WithdrawFunds";
import {Overview} from "./Overview";
import {DebugPanel} from "./DebugPanel";
import {MoveFunds} from "./MoveFunds";
import {LockFunds} from "./LockFunds";
import {ManageKeys} from "./ManageKeys";
import './Layout.css'

import moreIcon from '../assets/more.png'
import moreIconSelected from '../assets/more-selected.png'
import homeIcon from '../assets/home.png'
import homeIconSelected from '../assets/home-selected.png'
import addIcon from '../assets/add.png'
import addIconSelected from '../assets/add-selected.png'
import removeIcon from '../assets/remove.png'
import removeIconSelected from '../assets/remove-selected.png'
import {Divider, Visibility} from "../util/util";

export class Layout extends Component {
  state = {route: Overview as any};

  moreMenuItems = new Map<any, string> ([
    [Transactions, "Transactions"],
    [MoveFunds, "Move Funds"],
    [LockFunds, "Lock / Unlock Funds"],
    [ManageKeys, "Manage Keys"],
    [DebugPanel, "Debug Panel"]
  ]);

// @formatter:off
  render() {
    let moreItemsSelected = Array.from(this.moreMenuItems.keys()).includes(this.state.route);
    return (
      <Container className="main-content no-pad">
        <Row>
          <Col>
            <Container><Header/></Container>
            <Divider/>
            <Navbar>
              <this.NavButton route={Overview} icon={homeIcon} iconSelected={homeIconSelected}>Overview </this.NavButton>
              <this.NavButton route={AddFunds} icon={addIcon} iconSelected={addIconSelected}>Add </this.NavButton>
              <this.NavButton route={WithdrawFunds} icon={removeIcon} iconSelected={removeIconSelected}>Withdraw </this.NavButton>
                <OverlayTrigger
                  rootClose={true} trigger="click" placement='auto'
                  overlay={
                    <Popover id='moreitems-popover'>
                      <Popover.Content onClick={()=>document.body.click()}>
                        <ListGroup variant="flush">{
                          Array.from(this.moreMenuItems.entries()).map(([key,value])=>{
                              return <ListGroupItem key={key.toString()}><this.NavRow route={key}>{value}</this.NavRow></ListGroupItem>
                            })
                          }</ListGroup>
                      </Popover.Content>
                    </Popover>
                  }
                >
                  <Button className={"Layout-nav-button "}>
                      <Image src={moreItemsSelected ? moreIconSelected : moreIcon}/>
                      <Nav.Link className={moreItemsSelected ? "selected" : ""}>More</Nav.Link>
                  </Button>
                </OverlayTrigger>
            </Navbar>
            <Divider/>
          </Col>
        </Row>
        <Row>
          <Col>
            <Visibility visible={this.state.route === Overview}><Overview/></Visibility>
            <Visibility visible={this.state.route === AddFunds}><AddFunds/></Visibility>
            <Visibility visible={this.state.route === WithdrawFunds}><WithdrawFunds/></Visibility>
            <Visibility visible={this.state.route === Transactions}><Transactions/> </Visibility>
            <Visibility visible={this.state.route === MoveFunds}><MoveFunds/> </Visibility>
            <Visibility visible={this.state.route === LockFunds}><LockFunds/> </Visibility>
            <Visibility visible={this.state.route === ManageKeys}><ManageKeys/> </Visibility>
            <Visibility visible={this.state.route === DebugPanel}><DebugPanel/> </Visibility>
          </Col>
        </Row>
      </Container>
    );
  }
  // @formatter:on

  NavButton: FC<{ route: any, icon: any, iconSelected: any }> = (props) => {
    let selected = this.state.route === props.route;
    let showIcon = selected ? props.iconSelected : props.icon;
    return (
      <Nav className="Layout-nav-button"
           onClick={() => this.setState({route: props.route})}>
        <Image src={showIcon}/>
        <Nav.Link className={selected ? "selected" : ""}>{props.children}</Nav.Link>
      </Nav>
    );
  };

  NavRow: FC<{ route: any }> = (props) => {
    let selected = this.state.route === props.route;
    return (
      <Nav.Link
        className={"Layout-nav-row "+ (selected ? "selected" : "")}
        onClick={() => this.setState({route: props.route})}>
          {props.children}
      </Nav.Link>
    );
  };
}


