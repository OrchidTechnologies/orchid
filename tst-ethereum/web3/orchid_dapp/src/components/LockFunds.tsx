import React, {Component} from "react";
import {LockStatus} from "./LockStatus";
import {LotteryPot, orchidLock, orchidUnlock} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";
import {TransactionResult, TxState} from "./TransactionResult";

interface LockFundsState {
  pot: LotteryPot | null,
  formValid: boolean,
}

export class LockFunds extends Component {

  state: TxState & LockFundsState = {
    pot: null,
    formValid: true,
    running: false,
    result: "",
    txId: ""
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe((pot: LotteryPot) => {
      this.setState({
        pot: pot
      });
    });
  }

  private async lockOrUnlock() {
    if (this.state.pot == null) {
      return;
    }
    this.setState({
      formValid: false,
      running: true
    });
    try {
      let txId = (this.state.pot.isUnlocked() || this.state.pot.isUnlocking()) ? await orchidLock() : await orchidUnlock();
      this.setState({
        running: false,
        text: "Transaction Complete!",
        txId: txId,
        formValid: true
      });
      let api = OrchidAPI.shared();
      api.updateAccount().then();
    } catch (err) {
      this.setState({
        running: false,
        text: `Transaction Failed: ${err}`,
        formValid: true
      });
    }
  }

  render() {
    if (this.state.pot == null) {
      return <div/>;
    }
    let text = (this.state.pot.isUnlocked() || this.state.pot.isUnlocking()) ? "Lock" : "Unlock";
    return (
        <div>
          <label className="title">Lock / Unlock Funds</label>
          <p className="instructions">
            To withdraw your full balance including the escrow the account must be unlocked.
            Funds will be available at the time shown below. If you wish to cancel the withdrawal
            process and continue using your escrow re-lock your escrow.
          </p>
          <LockStatus/>
          <div style={{marginTop: '24px'}} className="submit-button">
            <button
                onClick={(_) => {
                  this.lockOrUnlock().then()
                }}
                disabled={!this.state.formValid}
            ><span>{text}</span></button>
          </div>
          <TransactionResult
              running={this.state.running}
              text={this.state.result}
              txId={this.state.txId}
          />
        </div>
    );
  }
}

