import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {orchidMoveFundsToEscrow, oxtToWei, weiToOxtString} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Container} from "react-bootstrap";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class MoveFunds extends Component {

  state = {
    moveAmount: null as number | null,
    amountError: true,
    potBalance: null as BigInt | null,
    tx: new TransactionStatus()
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe(pot => {
      this.setState({potBalance: pot.balance});
    });
  }

  async submitMoveFunds() {
    let api = OrchidAPI.shared();
    let wallet = api.wallet.value;
    let signer = api.signer.value;
    if (wallet === undefined || signer === undefined || this.state.moveAmount == null) {
      return;
    }
    this.setState({tx: TransactionStatus.running()});

    try {
      const moveEscrowWei = oxtToWei(this.state.moveAmount);
      let txId = await orchidMoveFundsToEscrow(wallet.address, signer.address, moveEscrowWei);
      await api.updateLotteryPot();
      this.setState({tx: TransactionStatus.result(txId, "Transaction Complete!")});
    } catch (err) {
      this.setState({tx: TransactionStatus.error(`Transaction Failed: ${err}`)});
    }
  }

  render() {
    let api = OrchidAPI.shared();
    let submitEnabled = api.wallet.value !== null
        && !this.state.tx.isRunning()
        && this.state.moveAmount != null;
    return (
        <Container className="form-style">
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
                this.setState({
                  moveAmount: amount,
                  amountError: !valid
                });
              }}
          />
          <SubmitButton onClick={() => this.submitMoveFunds().then()} enabled={submitEnabled}/>
          <TransactionProgress /*ref={txResult}*/ tx={this.state.tx}/>
        </Container>
    );
  }
}

