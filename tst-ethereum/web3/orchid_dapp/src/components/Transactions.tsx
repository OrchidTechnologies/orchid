import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {weiToOxtString} from "../api/orchid-eth";
import {EtherscanIO, LotteryPotUpdateEvent} from "../api/etherscan-io";
import './Transactions.css'
import {Container} from "react-bootstrap";

export class Transactions extends Component {
  state = {
    events: [] as LotteryPotUpdateEvent[]
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.transactions_wait.subscribe((events) => {
      this.setState({
        events: events
      });
    });
  }

  render() {
    return (
        <Container className="form-style">
          <label className="title">Transactions</label>
          <div className="transactions-list">
            <div className="transactions-header-row">
              <label className="transactions-col">Date</label>
              <label className="transactions-col2">Balance</label>
              <label className="transactions-col3">Tx</label>
            </div>
            <hr/>
            {!this.state.events.length && <div className="loading">Loading...</div>}
            {this.state.events.map((ev) => {
              let balance = weiToOxtString(ev.balance, 4);
              let date = ev.timeStamp.toLocaleDateString('en-US');
              let txHash = ev.transactionHash;
              let txLink = EtherscanIO.txLink(txHash);
              return (
                  <div className="transactions-row" key={txHash}>
                    <label className="transactions-col">{date}</label>
                    <label className="transactions-col2">{balance} OXT</label>
                    <label className="transactions-col3">
                      <a target="_blank" rel="noopener noreferrer" href={txLink}>{txHash}</a></label>
                  </div>
              );
            })}
          </div>
        </Container>
    );
  }
}

