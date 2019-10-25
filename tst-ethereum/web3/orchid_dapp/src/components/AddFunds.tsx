import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {orchidAddFunds, oxtToWeiString} from "../api/orchid-eth";
import {Divider, errorClass, parseFloatSafe} from "../util/util";
import {TransactionResult} from "./TransactionResult";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'

export class AddFunds extends Component {
  txResult = React.createRef<TransactionResult>();

  state = {
    addAmount: null as number | null,
    addEscrow: 0,
    amountError: true,
    escrowError: false,
    // tx
    running: false,
    text: "",
    txId: "",
  };

  async submitAddFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    console.log("submit add funds: ", account, this.state.addAmount, this.state.addEscrow);
    if (account == null
      || this.state.addAmount == null
      || this.state.addEscrow == null) {
      return;
    }

    this.setState({running: true});
    if (this.txResult.current != null) {
      this.txResult.current.scrollIntoView();
    }
    try {
      const amountWei = oxtToWeiString(this.state.addAmount);
      const escrowWei = oxtToWeiString(this.state.addEscrow);
      let potAddress = account.address;

      let txId = await orchidAddFunds(potAddress, amountWei, escrowWei);
      this.setState({
        running: false,
        text: "Transaction Complete!",
        txId: txId,
      });

      api.updateAccount().then();
      api.updateTransactions().then();
    } catch (err) {
      this.setState({
        running: false,
        text: "Transaction Failed.",
      });
    }
  };

  render() {
    let submitEnabled =
      OrchidAPI.shared().account.value !== null
      && !this.state.running
      && !this.state.amountError
      && !this.state.escrowError;
    return (
      <Container className="form-style">
        <label className="title">Add Funds</label>

        {/*Balance*/}
        <Row className="form-row" noGutters={true}>
          <Col>
            <label>Add to Balance<span
              className={errorClass(this.state.amountError)}> *</span></label>
          </Col>
          <Col>
            <input
              className="editable"
              onInput={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                this.setState({
                  addAmount: amount,
                  amountError: amount == null
                });
              }}
              type="number"
              placeholder="0.00"
            />
          </Col>
        </Row>

        {/*Deposit*/}
        <Row className="form-row" noGutters={true}>
          <Col>
            <label>Add to Deposit<span
              className={errorClass(this.state.escrowError)}> *</span></label>
          </Col>
          <Col>
            <input
              className="editable"
              onInput={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                this.setState({
                  addEscrow: amount,
                  escrowError: amount == null
                });
              }}
              type="number" placeholder="0.00"
              // defaultValue={"0.00"}
            />
          </Col>
        </Row>

        <p className="instructions">
          Your deposit secures access to the Orchid network and demonstrates authenticity to
          bandwidth sellers.
        </p>
        <Divider noGutters={true}/>

        {/*Total*/}
        <Row className="total-row" noGutters={true}>
          <Col>
            <label>Total</label>
          </Col>
          <Col>
            <div className="oxt-1">30.00 OXT</div>
          </Col>
        </Row>

        <SubmitButton onClick={() => this.submitAddFunds().then()} enabled={submitEnabled}>
          Add OXT
        </SubmitButton>

        <TransactionResult ref={this.txResult}
                           running={this.state.running}
                           text={this.state.text}
                           txId={this.state.txId}
        />
      </Container>
    );
  }
}


