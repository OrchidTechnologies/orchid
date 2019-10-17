import React, {Component} from "react";
import {LotteryPot} from "../api/orchid-eth";
import {OrchidAPI} from "../api/orchid-api";

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
      text = "Locked";
    } else {
      if (this.state.pot.unlock > new Date()) {
        icon = "🔒";
        text = `Locked until: ${this.state.pot.unlock.toLocaleString('en-US')}`;
      } else {
        icon = "🔓";
        text = "Unlocked";
      }
    }
    // language=HTML
    return (
        <div>
          <label
              style={{fontWeight: 'bold', marginTop: '12px'}}>Funds Status:
            <span style={{marginLeft: '8px'}}>{icon}</span>
          </label>
          <span>{text}</span>
        </div>
    );
  }
}


