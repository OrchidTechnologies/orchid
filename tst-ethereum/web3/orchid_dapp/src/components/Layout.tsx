import React, {Component, FC} from "react";
import {Col, Container, Image, Nav, Navbar, Row} from "react-bootstrap";
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

export class Layout extends Component {
  state = {route: Overview as any};

  render() {
    return (
      <Container className={"main-content"}>
        <Header/>
        <Navbar>
          <this.NavButton route={Overview} icon={homeIcon} iconSelected={homeIconSelected}>Overview</this.NavButton>
          <this.NavButton route={AddFunds} icon={addIcon} iconSelected={addIconSelected}>Add</this.NavButton>
          <this.NavButton route={WithdrawFunds} icon={removeIcon} iconSelected={removeIconSelected}>Withdraw</this.NavButton>
          <this.NavButton route={MoreItems} icon={moreIcon} iconSelected={moreIconSelected}>More</this.NavButton>
        </Navbar>
        <Visibility visible={this.state.route === MoreItems}><MoreItems/> </Visibility>
        <Visibility visible={this.state.route === Overview}><Overview/></Visibility>
        <Visibility visible={this.state.route === AddFunds}><AddFunds/></Visibility>
        <Visibility visible={this.state.route === WithdrawFunds}><WithdrawFunds/></Visibility>
      </Container>
    );
  }

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
}

export class MoreItems extends Component {
  state = {route: null as any};

  render() {
    return (
      <div style={{display: "flex", overflow: 'hidden'}}>
        <Container style={{width: '100%', flexShrink: 0}}
             className={"more-items " + (this.state.route == null ? "onscreen" : "push-left")}>
          <Col>
            <this.NavRow route={Transactions}>Transactions</this.NavRow>
            <this.Divider/>
            <this.NavRow route={MoveFunds}>Move Funds</this.NavRow>
            <this.Divider/>
            <this.NavRow route={LockFunds}>Lock / Unlock Funds</this.NavRow>
            <this.Divider/>
            <this.NavRow route={ManageKeys}>Manage Keys</this.NavRow>
            <this.Divider/>
            <this.NavRow route={DebugPanel}>Debug Panel</this.NavRow>
          </Col>
        </Container>
        <div style={{width: '100%', flexShrink: 0}}
             className={"more-items " + (this.state.route != null ? "push-left" : "onscreen")}>
          <Visibility visible={this.state.route != null}>
            <this.BackButton/>
          </Visibility>
          <Visibility visible={this.state.route === Transactions}><Transactions/> </Visibility>
          <Visibility visible={this.state.route === MoveFunds}><MoveFunds/> </Visibility>
          <Visibility visible={this.state.route === LockFunds}><LockFunds/> </Visibility>
          <Visibility visible={this.state.route === ManageKeys}><ManageKeys/> </Visibility>
          <Visibility visible={this.state.route === DebugPanel}><DebugPanel/> </Visibility>
        </div>
      </div>
    );
  }

  BackButton: FC = () => {
    return <Col onClick={() => this.setState({route: null})}>
      <Row className="back-button">
        <span style={{marginRight: '8px'}}>&lt;</span><span>Back</span>
        <this.Divider/>
      </Row>
    </Col>
  };

  NavRow: FC<{ route: any }> = (props) => {
    return (
      <Row className="Layout-nav-row justify-content-between"
           onClick={() => this.setState({route: props.route})}>
        <span>{props.children}</span>
      </Row>
    );
  };

  Divider: FC = () => {
    return <Row
      style={{
        height: '1px',
        backgroundColor: 'lightGrey'
      }}/>
  };
}

const Visibility: FC<{ visible: boolean }> = (props) => {
  return <div className={props.visible ? "" : "hidden-after-300"}>{props.children}</div>
};

