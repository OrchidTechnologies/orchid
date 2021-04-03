import React, {Component} from "react";
import {LockStatus} from "./LockStatus";
import {LotteryPot} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {Container} from "react-bootstrap";
import {S} from "../i18n/S";
import {Subscription} from "rxjs";

export class LockFunds extends Component<any, any> {

  state = {
    pot: null as LotteryPot | null,
    tx: new TransactionStatus()
  };
  subscriptions: Subscription [] = [];

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    this.subscriptions.push(
    api.lotteryPot_wait.subscribe((pot: LotteryPot) => {
      this.setState({
        pot: pot
      });
    }));
  }

  componentWillUnmount(): void {
    this.subscriptions.forEach(sub => {
      sub.unsubscribe()
    })
  }

  private async lockOrUnlock()
  {
    let api = OrchidAPI.shared();
    if (!api.eth) { return }
    const wallet = api.wallet.value;
    const signer = api.signer.value;

    if (!this.state.pot || !wallet || !signer ) {
      return;
    }
    this.setState({tx: TransactionStatus.running()});
    try {
      let pot = this.state.pot;
      let txId = (pot.isUnlocked || pot.isUnlocking) ?
        await api.eth.orchidLock(pot, wallet.address, signer.address) :
        await api.eth.orchidUnlock(pot, wallet.address, signer.address);
      this.setState({tx: TransactionStatus.result(txId, S.transactionComplete)});
      api.updateLotteryPot().then();
    } catch (err) {
      console.log("error: ", err);
      this.setState({tx: TransactionStatus.error(`${S.transactionFailed}: ${err}`)});
    }
  }

  render() {
    if (this.state.pot == null) {
      return <div/>;
    }
    let text = (this.state.pot.isUnlocked || this.state.pot.isUnlocking) ? S.lock : S.unlock;
    let api = OrchidAPI.shared();
    let submitEnabled = !api.eth || !this.state.tx.isRunning;
    return (
      <Container className="form-style">
        <label className="title">{S.lockUnlockFunds}</label>
        <p className="instructions">
          {S.toWithdrawYourFullBalance + "  "}
          {S.fundsWillBeAvailableAt+ "  "}
          {S.ifYouWishToCancelWithdrawal}
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
        <TransactionProgress tx={this.state.tx}/>
      </Container>
    );
  }
}

