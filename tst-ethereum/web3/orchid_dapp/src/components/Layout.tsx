import React from "react";
import './LayoutDesktop.css'
import {Container, Dropdown, Nav, Navbar} from "react-bootstrap";
import Header from "./Header";

import {Transactions} from "./Transactions";
import {BrowserRouter, Link, Route, Switch} from "react-router-dom";
import {AddFunds} from "./AddFunds";
import {WithdrawFunds} from "./WithdrawFunds";
import './Layout.css'
import Overview from "./Overview";
import DebugPanel from "./DebugPanel";
import {MoveFunds} from "./MoveFunds";
import {LockFunds} from "./LockFunds";
import {ManageKeys} from "./ManageKeys";

export const Layout: React.FC = () => {
  return (
      <BrowserRouter>
        <Container>
          <Container className="form-style">
            <Header/>
            <Navbar expand="md">
              <Dropdown>
                <Dropdown.Toggle id="dropdown">More</Dropdown.Toggle>
                <Dropdown.Menu>
                  <Dropdown.Item><Link className="nav-link" to="/transactions">Transactions</Link></Dropdown.Item>
                  <Dropdown.Item><Link className="nav-link" to="/move">Move Funds</Link></Dropdown.Item>
                  <Dropdown.Item><Link className="nav-link" to="/lock">Lock/Unlock Funds</Link></Dropdown.Item>
                  <Dropdown.Item><Link className="nav-link" to="/keys">Manage Keys</Link></Dropdown.Item>
                  <Dropdown.Item><Link className="nav-link" to="/debug">Debug Panel</Link></Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
              <Navbar.Toggle aria-controls="basic-navbar-nav"/>
              <Navbar.Collapse id="basic-navbar-nav">
                <Nav className="mr-auto">
                  {/*<Nav.Link href="/">Home</Nav.Link>*/}
                  {/*Nav.Link broken with typescript, adding the class to Link*/}
                  <Link className="nav-link" to="/">Overview</Link>
                  <Link className="nav-link" to="/add">Add Funds</Link>
                  <Link className="nav-link" to="/withdraw">Withdraw Funds</Link>
                </Nav>
              </Navbar.Collapse>
            </Navbar>
          </Container>
          <div className="content form-style">
            <Switch>
              <Route exact path='/' component={Overview}/>
              <Route path='/transactions' component={Transactions}/>
              <Route path='/add' component={AddFunds}/>
              <Route path='/withdraw' component={WithdrawFunds}/>
              <Route path='/move' component={MoveFunds}/>
              <Route path='/debug' component={DebugPanel}/>
              <Route path='/lock' component={LockFunds}/>
              <Route path='/keys' component={ManageKeys}/>
            </Switch>
          </div>
        </Container>
      </BrowserRouter>
  );
};


