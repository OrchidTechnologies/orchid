import React, {Component} from 'react';
import {OrchidAPI} from "../api/orchid-api";
import {weiToOxtString} from "../api/orchid-eth";
import {LockStatus} from "./LockStatus";
import {errorClass} from "../util/util";
import './Balances.css'
import {Button, Col, Container, Row} from "react-bootstrap";
import {Subscription} from "rxjs";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class Balances extends Component {
  state = {
    signerAddress: "",
    walletAddress: "",
    ethBalance: "",
    ethBalanceError: true,
    oxtBalance: "",
    oxtBalanceError: true,
    potBalance: "",
    potEscrow: "",
  };
  subscriptions: Subscription [] = [];
  walletAddressInput = React.createRef<HTMLInputElement>();
  signerAddressInput = React.createRef<HTMLInputElement>();

  componentDidMount(): void {
    let api = OrchidAPI.shared();

    this.subscriptions.push(
      api.signer_wait.subscribe(signer => {
        console.log("Funding from account: ", signer.wallet.address);
        console.log("Balance: ", signer.wallet.ethBalance);
        this.setState({
          signerAddress: signer.address,
          walletAddress: signer.wallet.address,
          ethBalance: weiToOxtString(signer.wallet.ethBalance, 4),
          ethBalanceError: signer.wallet.ethBalance <= BigInt(0),
          oxtBalance: weiToOxtString(signer.wallet.oxtBalance, 4),
          oxtBalanceError: signer.wallet.oxtBalance <= BigInt(0),
        });
      }));

    this.subscriptions.push(
      api.lotteryPot_wait.subscribe(pot => {
        this.setState({
          potBalance: weiToOxtString(pot.balance, 4),
          potEscrow: weiToOxtString(pot.escrow, 4)
        });
      }));
  }


  componentWillUnmount(): void {
    this.subscriptions.forEach(sub => {
      sub.unsubscribe()
    })
  }

  copyWalletAddress() {
    if (this.walletAddressInput.current == null) {
      return;
    }
    this.walletAddressInput.current.select();
    document.execCommand('copy');
  };

  copySignerAddress() {
    if (this.signerAddressInput.current == null) {
      return;
    }
    this.signerAddressInput.current.select();
    document.execCommand('copy');
  };

  render() {
    return (
      <Container className="Balances form-style">
        <label className="title">Info</label>

        {/*wallet address*/}
        <label style={{fontWeight: "bold"}}>Wallet Address </label>
        <Row noGutters={true}>
          <Col style={{flexGrow: 10}}>
            <input type="text"
                   style={{textOverflow: "ellipsis"}}
                   ref={this.walletAddressInput}
                   value={this.state.walletAddress} placeholder="Address" readOnly/>
          </Col>
          <Col style={{marginLeft: '8px'}}>
            <Button variant="light" onClick={this.copyWalletAddress.bind(this)}>Copy</Button>
          </Col>
        </Row>

        {/*wallet balance*/}
        <div className="form-row col-1-1">
          <div className="form-row col-1-2">
            <label className="form-row-label">ETH</label>
            <span className={errorClass(this.state.ethBalanceError)}> * </span>
            <input className="form-row-field" type="text"
                   value={this.state.ethBalance}
                   readOnly/>
          </div>
          <div className="form-row col-1-2">
            <label className="form-row-label">OXT</label>
            <span className={errorClass(this.state.oxtBalanceError)}> * </span>
            <input className="form-row-field" type="text"
                   value={this.state.oxtBalance}
                   readOnly/>
          </div>
        </div>

        {/*signer address*/}
        <label style={{fontWeight: "bold", marginTop: "16px"}}>Signer Address </label>
        <Row noGutters={true}>
          <Col style={{flexGrow: 10}}>
            <input type="text"
                   style={{textOverflow: "ellipsis"}}
                   ref={this.signerAddressInput}
                   value={this.state.signerAddress} placeholder="Address" readOnly/>
          </Col>
          <Col style={{marginLeft: '8px'}}>
            <Button variant="light" onClick={this.copySignerAddress.bind(this)}>Copy</Button>
          </Col>
        </Row>

        {/*pot balance and escrow*/}
        <label style={{fontWeight: "bold", marginTop: "16px"}}>Lottery Pot</label>
        <div className="form-row col-1-1">
          <div className="form-row col-1-2">
            <label className="form-row-label">Balance</label>
            <input className="form-row-field"
                   value={this.state.potBalance}
                   type="text" readOnly/>
          </div>
          <div className="form-row col-1-2">
            <label className="form-row-label">Escrow</label>
            <input className="form-row-field"
                   value={this.state.potEscrow}
                   type="text" readOnly/>
          </div>
        </div>

        {/*pot lock status*/}
        <div style={{marginTop: "16px"}}/>
        <LockStatus/>
      </Container>
    );
  }
}


