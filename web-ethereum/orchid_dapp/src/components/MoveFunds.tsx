import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {oxtToKeiki, keikiToOxtString} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Container} from "react-bootstrap";
import {S} from "../i18n/S";
import {Subscription} from "rxjs";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class MoveFunds extends Component {

  state = {
    moveAmount: null as number | null,
    amountError: true,
    potBalance: null as BigInt | null,
    tx: new TransactionStatus()
  };
  subscriptions: Subscription [] = [];

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    this.subscriptions.push(
      api.lotteryPot_wait.subscribe(pot => {
        this.setState({potBalance: pot.balance});
      }));
  }

  componentWillUnmount(): void {
    this.subscriptions.forEach(sub => {
      sub.unsubscribe()
    })
  }

  async submitMoveFunds() {
    let api = OrchidAPI.shared();
    let wallet = api.wallet.value;
    let signer = api.signer.value;
    if (!wallet || !signer
      || this.state.moveAmount == null
      || this.state.potBalance == null
    ) {
      return;
    }
    this.setState({tx: TransactionStatus.running()});

    try {
      const moveEscrowWei = oxtToKeiki(this.state.moveAmount);
      let txId = await api.eth.orchidMoveFundsToEscrow(
        wallet.address, signer.address, moveEscrowWei, this.state.potBalance);
      await api.updateLotteryPot();
      this.setState({tx: TransactionStatus.result(txId, S.transactionComplete)});
    } catch (err) {
      this.setState({tx: TransactionStatus.error(`${S.transactionFailed}: ${err}`)});
    }
  }

  render() {
    let api = OrchidAPI.shared();
    let submitEnabled = api.wallet.value !== null
      && !this.state.tx.isRunning()
      && this.state.moveAmount != null;
    return (
      <Container className="form-style">
        <label className="title">{S.moveFunds}</label>
        <p className="instructions">
          {S.moveFundsFromYourLotteryPot + "  "}
          {S.balanceFundsAreUsedByOrchid + "  "}
          {S.depositFundsAreRequiredToParticipate}
        </p>
        <label>{S.availableLotteryPotBalance}</label>
        <input type="number" className="pot-balance"
               placeholder={S.amountInOXT}
               value={this.state.potBalance == null ? "" : keikiToOxtString(this.state.potBalance, 4)}
               readOnly/>
        <label>{S.moveToDepositAmount}<span className={errorClass(this.state.amountError)}> *</span></label>
        <input
          type="number"
          placeholder={S.amountInOXT}
          className="editable"
          onInput={(e) => {
            let amount = parseFloatSafe(e.currentTarget.value);
            const valid = amount != null && amount > 0
              && (this.state.potBalance == null || BigInt(amount) <= this.state.potBalance);
            this.setState({
              moveAmount: amount,
              amountError: !valid
            });
          }}
        />
        <SubmitButton onClick={() => this.submitMoveFunds().then()} enabled={submitEnabled}/>
        <TransactionProgress tx={this.state.tx}/>
      </Container>
    );
  }
}

