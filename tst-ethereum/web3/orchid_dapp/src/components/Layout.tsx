import React, {Component} from "react";
import {Container, Dropdown, Nav, Navbar} from "react-bootstrap";
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

export class Layout extends Component {
  state = {route: Overview};

  render() {
    return (
        <Container>
          <Container className="form-style">
            <Header/>
            <Navbar expand={true}>
              <Dropdown>
                <Dropdown.Toggle id="dropdown">More</Dropdown.Toggle>
                <Dropdown.Menu>
                  <Dropdown.Item>{this.navLink("Transactions", Transactions)}</Dropdown.Item>
                  <Dropdown.Item>{this.navLink("Move Funds", MoveFunds)}</Dropdown.Item>
                  <Dropdown.Item>{this.navLink("Lock/Unlock Funds", LockFunds)}</Dropdown.Item>
                  <Dropdown.Item>{this.navLink("Manage Keys", ManageKeys)}</Dropdown.Item>
                  <Dropdown.Item>{this.navLink("Debug Panel", DebugPanel)}</Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
              <Navbar.Toggle aria-controls="basic-navbar-nav"/>
              <Navbar.Collapse id="basic-navbar-nav">
                <Nav className="mr-auto">
                  {this.navLink("Home", Overview)}
                  {this.navLink("Add", AddFunds)}
                  {this.navLink("Withdraw", WithdrawFunds)}
                </Nav>
              </Navbar.Collapse>
            </Navbar>
          </Container>
          <Container className="content form-style">
            {this.linkedContent(Overview, <Overview/>)}
            {this.linkedContent(Transactions, <Transactions/>)}
            {this.linkedContent(AddFunds, <AddFunds/>)}
            {this.linkedContent(WithdrawFunds, <WithdrawFunds/>)}
            {this.linkedContent(MoveFunds, <MoveFunds/>)}
            {this.linkedContent(DebugPanel, <DebugPanel/>)}
            {this.linkedContent(LockFunds, <LockFunds/>)}
            {this.linkedContent(ManageKeys, <ManageKeys/>)}
          </Container>
        </Container>
    );
  }

  private navLink(title: string, route: any) {
    return <div onClick={() => this.setState({route: route})}>
      <Nav.Link>{title}</Nav.Link>
    </div>;
  }

  private linkedContent(route: any, content: any) {
    return <div className={route === this.state.route ? "" : "hidden"}>{content}</div>
  }
}


