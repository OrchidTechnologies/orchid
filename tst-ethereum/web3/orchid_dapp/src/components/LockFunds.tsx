import React, {Component} from "react";
import {LockStatus} from "./LockStatus";
import {LotteryPot, orchidLock, orchidUnlock} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {Container} from "react-bootstrap";

export class LockFunds extends Component {

  state = {
    pot: null as LotteryPot | null,
    tx: new TransactionStatus()
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe((pot: LotteryPot) => {
      this.setState({
        pot: pot
      });
    });
  }

  private async lockOrUnlock()
  {
    let api = OrchidAPI.shared();
    const wallet = api.wallet.value;
    const signer = api.signer.value;

    if (this.state.pot == null
      || wallet === undefined
      || signer === undefined
    ) {
      return;
    }
    this.setState({tx: TransactionStatus.running()});
    try {
      let txId = (this.state.pot.isUnlocked() || this.state.pot.isUnlocking()) ?
        await orchidLock(wallet.address, signer.address) :
        await orchidUnlock(wallet.address, signer.address);
      this.setState({tx: TransactionStatus.result(txId, "Transaction Complete!")});
      api.updateLotteryPot().then();
    } catch (err) {
      console.log("error: ", err);
      this.setState({tx: TransactionStatus.error(`Transaction Failed: ${err}`)});
    }
  }

  render() {
    if (this.state.pot == null) {
      return <div/>;
    }
    let text = (this.state.pot.isUnlocked() || this.state.pot.isUnlocking()) ? "Lock" : "Unlock";
    let submitEnabled = !this.state.tx.isRunning();
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
        <TransactionProgress /*ref={txResult}*/ tx={this.state.tx}/>
      </Container>
    );
  }
}

