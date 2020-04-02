import React, {Component} from "react";
import {LotteryPot} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";
import {S} from "../i18n/S";

export class LockStatus extends Component {
  state = {
    pot: null as LotteryPot | null
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe((pot: LotteryPot) => {
      this.setState({
        pot: pot
      });
    });
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


