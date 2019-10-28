import React, {Component} from "react";
import {LockStatus} from "./LockStatus";
import {LotteryPot, orchidLock, orchidUnlock} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";
import {TxProps, TxResult} from "./TxResult";
import {Container} from "react-bootstrap";

export class LockFunds extends Component {

  state = {
    pot: null as LotteryPot | null,
    tx: new TxProps()
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
    this.setState({tx: TxProps.running()});
    try {
      let txId = (this.state.pot.isUnlocked() || this.state.pot.isUnlocking()) ? await orchidLock() : await orchidUnlock();
      this.setState({tx: TxProps.result("Transaction Complete!", txId)});

      let api = OrchidAPI.shared();
      api.updateAccount().then();
    } catch (err) {
      console.log("error: ", err);
      this.setState({tx: TxProps.error(`Transaction Failed: ${err}`)});
    }
  }

  render() {
    if (this.state.pot == null) {
      return <div/>;
    }
    let text = (this.state.pot.isUnlocked() || this.state.pot.isUnlocking()) ? "Lock" : "Unlock";
    let submitEnabled = !this.state.tx.running;
    return (
      <Container className="form-style">
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
            disabled={!submitEnabled}
          ><span>{text}</span></button>
        </div>
        <TxResult /*ref={txResult}*/ tx={this.state.tx}/>
      </Container>
    );
  }
}

