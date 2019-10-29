import React, {Component} from "react";
import logo from '../assets/name-logo.svg'
import tokenLogo from '../assets/orchid-token-purple.svg'
import {Col, Container, Row} from "react-bootstrap";
import './Header.css';
import {OrchidAPI} from "../api/orchid-api";
import {weiToOxtString} from "../api/orchid-eth";

class Header extends Component {
  state = {
    oxtBalance: null as string | null,
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe(pot=>{
      this.setState({
        oxtBalance: weiToOxtString(pot.balance, 2),
      });
    });
  }

  render() {
    return (
      <Container>
        <Row noGutters={true} style={{marginBottom: '14px'}}>
          {/*Logo*/}
          <Col>
            <img style={{width: '130px', height: '56px', marginBottom: '16px'}}
                 src={logo} alt="Orchid Account"/>
          </Col>
          {/*Balance*/}
          <Col className={this.state.oxtBalance == null ? "hidden" : ""} style={{flexGrow: 2}}>
            <Row noGutters={true}>
              <Col>
                <div className="header-balance">BALANCE</div>
                <div className="header-balance-value">{this.state.oxtBalance || ""} OXT</div>
              </Col>
              <Col style={{flexGrow: 0}}>
                <img style={{
                  display: 'block',
                  marginTop: '6px',
                  marginLeft: '8px',
                  width: '24px', height: '24px'
                }} src={tokenLogo} alt="Orchid Account"/>
              </Col>
            </Row>
          </Col>
        </Row>
      </Container>
    );
  }
}

export default Header;
