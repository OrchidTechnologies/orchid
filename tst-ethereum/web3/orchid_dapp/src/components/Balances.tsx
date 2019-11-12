import React, {Component} from 'react';
import {OrchidAPI} from "../api/orchid-api";
import {weiToOxtString} from "../api/orchid-eth";
import {LockStatus} from "./LockStatus";
import {errorClass} from "../util/util";
import './Balances.css'
import {Container} from "react-bootstrap";
import {Subscription} from "rxjs";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class Balances extends Component {
  state = {
    walletAddress: "",
    ethBalance: "",
    ethBalanceError: true,
    oxtBalance: "",
    oxtBalanceError: true,
    potBalance: "",
    potEscrow: "",
  };
  subscriptions: Subscription [] = [];

  componentDidMount(): void {
    let api = OrchidAPI.shared();

    this.subscriptions.push(
      api.wallet_wait.subscribe(wallet => {
        console.log("Funding from account: ", wallet.address);
        console.log("Balance: ", wallet.ethBalance);
        this.setState({
          walletAddress: wallet.address,
          ethBalance: weiToOxtString(wallet.ethBalance, 4),
          ethBalanceError: wallet.ethBalance <= BigInt(0),
          oxtBalance: weiToOxtString(wallet.oxtBalance, 4),
          oxtBalanceError: wallet.oxtBalance <= BigInt(0),
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

  render() {
    return (
      <Container className="Balances form-style">
        <label className="title">Overview</label>
        {/*wallet*/}
        <label style={{fontWeight: "bold"}}>Wallet Address </label>
        <input type="text" value={this.state.walletAddress} placeholder="Address" readOnly/>

        {/*// wallet balance*/}
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

        {/*// pot balance and escrow*/}
        <label style={{fontWeight: "bold", marginTop: "12px"}}>Lottery Pot</label>
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

        {/*// pot lock status*/}
        <LockStatus/>
      </Container>
    );
  }
}


