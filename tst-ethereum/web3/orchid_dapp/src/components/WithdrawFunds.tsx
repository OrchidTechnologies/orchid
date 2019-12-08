import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {
  isEthAddress, oxtToWei, weiToOxtString,
  orchidWithdrawFunds, orchidWithdrawFundsAndEscrow
} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Address} from "../api/orchid-types";
import {Col, Container, Row} from "react-bootstrap";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class WithdrawFunds extends Component {
  txResult = React.createRef<TransactionProgress>();

  state = {
    potBalance: null as BigInt | null,
    potUnlocked: null as boolean | null,
    withdrawAmount: null as number | null,
    withdrawAll: false,
    sendToAddress: null as Address | null,
    amountError: true,
    addressError: true,
    tx: new TransactionStatus()
  };
  amountInput = React.createRef<HTMLInputElement>();

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe(pot => {
      this.setState({
        potBalance: pot.balance,
        potUnlocked: pot.isUnlocked()
      })
    });
  }

  async submitWithdrawFunds() {
    const api = OrchidAPI.shared();
    const wallet = api.wallet.value;
    const signer = api.signer.value;
    const withdrawAmount = this.state.withdrawAmount;
    const withdrawAll = this.state.withdrawAll;
    const targetAddress = this.state.sendToAddress;

    if (wallet === undefined
      || signer === undefined
      || (withdrawAmount == null && !withdrawAll)
      || withdrawAll == null
      || targetAddress == null
    ) {
      console.log("precondition error in withdraw");
      return;
    }
    this.setState({tx: TransactionStatus.running()});
    if (this.txResult.current != null) {
      this.txResult.current.scrollIntoView();
    }

    try {
      let txId;
      if (this.state.withdrawAll) {
        txId = await orchidWithdrawFundsAndEscrow(wallet.address, signer.address, targetAddress);
      } else {
        if (withdrawAmount == null) {
          return; // Shouldn't get here.
        }
        const withdrawWei = oxtToWei(withdrawAmount);
        txId = await orchidWithdrawFunds(wallet.address, signer.address, targetAddress, withdrawWei);
      }
      await api.updateLotteryPot();
      await api.updateWallet();
      this.setState({tx: TransactionStatus.result(txId, "Transaction Complete!")});
      api.updateTransactions().then();
    } catch (err) {
      this.setState({tx: TransactionStatus.error(`Transaction Failed: ${err}`)});
    }
  };

  render() {
    let withdrawAmount = this.state.withdrawAll ?
      weiToOxtString(this.state.potBalance || BigInt(0), 4) :
      this.state.withdrawAmount;

    let api = OrchidAPI.shared();
    let submitEnabled =
      !this.state.tx.isRunning()
      && api.wallet.value !== null
      && this.state.sendToAddress !== null
      && (this.state.withdrawAll || this.state.withdrawAmount !== null);

    let currentInputAmount = this.amountInput.current == null ? "" : this.amountInput.current.value;
    return (
      <Container className="form-style">
        <label className="title">Withdraw from balance</label>

        {/*Balance*/}
        <Row className="form-row">
          <Col>
            <label>Balance</label>
          </Col>
          <Col>
            <div className="oxt-1-pad">
              {this.state.potBalance == null ? "..." : weiToOxtString(this.state.potBalance, 2)}
            </div>
          </Col>
        </Row>

        <Row className="form-row">
          <Col>
            <label>Withdraw<span className={errorClass(this.state.amountError)}> *</span></label>
          </Col>
          <Col>
            <input
              ref={this.amountInput}
              type="number"
              className="withdraw-amount editable"
              placeholder="0.00"
              value={withdrawAmount == null ? currentInputAmount : withdrawAmount}
              onChange={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                const valid = amount != null && amount > 0
                  && (this.state.potBalance == null || oxtToWei(amount) <= this.state.potBalance);
                this.setState({
                  withdrawAmount: amount,
                  amountError: !valid
                });
              }}
            />
          </Col>
        </Row>

        <Row>
          <Col>
            <label>Withdrawing to:<span
              className={errorClass(this.state.addressError)}> *</span></label>
            <input
              type="text"
              className="send-to-address editable"
              placeholder="Address"
              onChange={(e) => {
                const address = e.currentTarget.value;
                const valid = isEthAddress(address);
                this.setState({
                  sendToAddress: valid ? address : null,
                  addressError: !valid
                });
              }}
            />
          </Col>
        </Row>

        {/*Withdraw all checkbox*/}
        <Row>
          <Col>
            <div className={this.state.potUnlocked ? "" : "disabled-faded"} style={{
              display: 'flex',
              alignItems: 'baseline',
            }}>
              <input
                type="checkbox"
                style={{transform: 'scale(2)', margin: '16px'}}
                onChange={(e) => {
                  const value = e.currentTarget.checked;
                  this.setState({withdrawAll: value});
                }}
              />
              <label>Withdraw Full Balance and Escrow</label>
            </div>
          </Col>
        </Row>

        <p className="instructions-narrow">
          Note: If an overdraft occurs on your Orchid<br/>
          balance, your deposit will be lost.
        </p>
        <div style={{marginTop: '16px'}}>
          <SubmitButton onClick={() => this.submitWithdrawFunds().then()} enabled={submitEnabled}>
            Withdraw OXT</SubmitButton>
        </div>

        <TransactionProgress ref={this.txResult} tx={this.state.tx}/>
      </Container>
    );
  }
}

