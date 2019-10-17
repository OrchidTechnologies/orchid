import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {BehaviorSubject, combineLatest} from "rxjs";
import {map} from "rxjs/operators";
import {orchidAddFunds, oxtToWeiString} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionResult} from "./TransactionResult";
import {SubmitButton} from "./SubmitButton";

export class AddFunds extends Component {
  addAmount = new BehaviorSubject<number | null>(null);
  addEscrow = new BehaviorSubject<number | null>(0);
  addFormValid = combineLatest([this.addAmount, this.addEscrow])
    .pipe(map(val => {
      const [amount, escrow] = val;
      let api = OrchidAPI.shared();
      return api.account.value !== null && amount != null && escrow != null;
    }));

  state = {
    formValid: false,
    amountError: true,
    escrowError: false,
    // tx
    running: false,
    text: "",
    txId: "",
  };

  componentDidMount(): void {
    this.addFormValid.subscribe(valid => {
      this.setState({formValid: valid});
    });
  }

  async submitAddFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;

    if (account == null
      || this.addAmount.value == null
      || this.addEscrow.value == null) {
      return;
    }

    this.setState({
      formValid: false,
      running: true
    });

    try {
      const amountWei = oxtToWeiString(this.addAmount.value);
      const escrowWei = oxtToWeiString(this.addEscrow.value);
      let potAddress = account.address;

      let txId = await orchidAddFunds(potAddress, amountWei, escrowWei);
      this.setState({
        running: false,
        text: "Transaction Complete!",
        txId: txId,
        formValid: true
      });

      api.updateAccount().then();
      api.updateTransactions().then();
    } catch (err) {
      this.setState({
        running: false,
        text: "Transaction Failed.",
        formValid: true
      });
    }
  };

  render() {
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
          className="add-amount editable"
          onInput={(e) => {
            let amount = parseFloatSafe(e.currentTarget.value);
            this.setState({ amountError: amount == null });
            this.addAmount.next(amount);
          }}
          type="number"
          placeholder="Amount in OXT"
        />
        <label>Add to Escrow Amount<span className={errorClass(this.state.escrowError)}> *</span></label>
        <input
          className="add-escrow editable"
          onInput={(e) => {
            let amount = parseFloatSafe(e.currentTarget.value);
            this.setState({ escrowError: amount == null });
            this.addEscrow.next(amount);
          }}
          type="number" placeholder="Amount in OXT"
          defaultValue={0}
        />
        <SubmitButton onClick={() => this.submitAddFunds().then()} enabled={this.state.formValid}/>
        <TransactionResult
          running={this.state.running}
          text={this.state.text}
          txId={this.state.txId}
        />
      </div>
    );
  }
}

