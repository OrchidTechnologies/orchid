import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {orchidAddFunds, oxtToWeiString} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionResult} from "./TransactionResult";
import {SubmitButton} from "./SubmitButton";

export class AddFunds extends Component {

  state = {
    addAmount: null as number | null,
    addEscrow: null as number | null,
    amountError: true,
    escrowError: false,
    // tx
    running: false,
    text: "",
    txId: "",
  };

  async submitAddFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    if (account == null
        || this.state.addAmount == null
        || this.state.addEscrow == null) {
      return;
    }

    this.setState({running: true});
    try {
      const amountWei = oxtToWeiString(this.state.addAmount);
      const escrowWei = oxtToWeiString(this.state.addEscrow);
      let potAddress = account.address;

      let txId = await orchidAddFunds(potAddress, amountWei, escrowWei);
      this.setState({
        running: false,
        text: "Transaction Complete!",
        txId: txId,
      });

      api.updateAccount().then();
      api.updateTransactions().then();
    } catch (err) {
      this.setState({
        running: false,
        text: "Transaction Failed.",
      });
    }
  };

  render() {
    let submitEnabled =
        OrchidAPI.shared().account.value !== null
        && !this.state.running
        && !this.state.amountError
        && !this.state.escrowError;
    return (
        <div>
          <label className="title">Add Funds</label>
          <p className="instructions">
            Add funds to your Lottery Pot balance and escrow. Balance funds are used by Orchid
            services
            and can be withdrawn at any time. Escrow funds are required to participate in the Orchid
            network and can be withdrawn after an unlock notice period.
          </p>

          <label>Add to Balance Amount<span className={errorClass(this.state.amountError)}> *</span></label>
          <input
              className="editable"
              onInput={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                this.setState({
                  addAmount: amount,
                  amountError: amount == null
                });
              }}
              type="number"
              placeholder="Amount in OXT"
          />
          <label>Add to Escrow Amount<span className={errorClass(this.state.escrowError)}> *</span></label>
          <input
              className="editable"
              onInput={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                this.setState({
                  addEscrow: amount,
                  escrowError: amount == null
                });
              }}
              type="number" placeholder="Amount in OXT"
              defaultValue={0}
          />
          <SubmitButton onClick={() => this.submitAddFunds().then()} enabled={submitEnabled}/>
          <TransactionResult
              running={this.state.running}
              text={this.state.text}
              txId={this.state.txId}
          />
        </div>
    );
  }
}


