import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {BehaviorSubject, combineLatest} from "rxjs";
import {map} from "rxjs/operators";
import {orchidMoveFundsToEscrow, oxtToWeiString, weiToOxtString} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionResult} from "./TransactionResult";
import {SubmitButton} from "./SubmitButton";

export class MoveFunds extends Component {

  moveEscrow = new BehaviorSubject<number | null>(null);
  moveFormValid = combineLatest([this.moveEscrow])
    .pipe(map(val => {
      const [escrowAmount] = val;
      let api = OrchidAPI.shared();
      return api.account.value !== null && escrowAmount != null;
    }));

  state = {
    potBalance: null as BigInt | null,
    formValid: false,
    running: false,
    text: "",
    txId: "",
    amountError: true,
  };

  componentDidMount(): void {
    this.moveFormValid.subscribe(valid => {
      this.setState({formValid: valid});
    });

    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe(pot => {
      this.setState({
        potBalance: pot.balance
      });
    });
  }

  async submitMoveFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    if (account == null
      || this.moveEscrow.value == null) {
      return;
    }
    this.setState({
      formValid: false,
      running: true
    });

    try {
      const moveEscrowWei = oxtToWeiString(this.moveEscrow.value);
      let txId = await orchidMoveFundsToEscrow(moveEscrowWei);
      this.setState({
        text: "Transaction Complete!",
        txId: txId,
        running: false,
        formValid: true
      });
      api.updateAccount().then();
    } catch (err) {
      this.setState({
        text: "Transaction Failed.",
        running: false,
        formValid: true
      });
    }
  }

  render() {
    return (
      <div>
        <label className="title">Move Funds</label>
        <p className="instructions">
          Move funds from your Lottery Pot balance to your escrow. Balance funds are used by
          Orchid services and can be withdrawn at any time. Escrow funds are required to participate in
          the Orchid network and can be withdrawn after an unlock notice period.
        </p>
        <label>Available Lottery Pot Balance Amount</label>
        <input type="number" className="pot-balance" placeholder="Amount in OXT"
               value={this.state.potBalance == null ? "" : weiToOxtString(this.state.potBalance, 4)}
               readOnly/>
        <label>Move to Escrow Amount<span className={errorClass(this.state.amountError)}> *</span></label>
        <input
          type="number" placeholder="Amount in OXT" className="editable"
          onInput={(e) => {
            let amount = parseFloatSafe(e.currentTarget.value);
            const valid = amount != null && amount > 0
              && (this.state.potBalance == null || BigInt(amount) <= this.state.potBalance);
            this.setState({ amountError: !valid });
            this.moveEscrow.next(valid ? amount : null);
          }}
        />
        <SubmitButton onClick={()=>this.submitMoveFunds().then()} enabled={this.state.formValid}/>
        <TransactionResult
          running={this.state.running}
          text={this.state.text}
          txId={this.state.txId}
        />
      </div>
    );
  }
}

