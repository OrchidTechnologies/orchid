import React, {Component} from "react";
import {LotteryPot} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";
import {S} from "../i18n/S";
import {Subscription} from "rxjs";

export class LockStatus extends Component {
  state = {
    pot: null as LotteryPot | null
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

  render() {
    if (this.state.pot === null) {
      return <div/>;
    }
    let icon: string, text: string;
    if (this.state.pot.unlock == null) {
      icon = "🔒";
      text = S.locked;
    } else {
      if (this.state.pot.unlock > new Date()) {
        icon = "🔒";
        text = `${S.lockedUntil}: ${this.state.pot.unlock.toLocaleString()}`;
      } else {
        icon = "🔓";
        text = S.unlocked;
      }
    }
    // language=HTML
    return (
      <div>
        <label
          style={{fontWeight: 'bold', marginTop: '12px'}}>{S.fundsStatus}:
          <span style={{marginLeft: '8px'}}>{icon}</span>
        </label>
        <span>{text}</span>
      </div>
    );
  }
}


