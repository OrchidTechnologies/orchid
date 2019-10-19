import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {
  isEthAddress, oxtToWei, oxtToWeiString,
  weiToOxtString,
  orchidWithdrawFunds,
  orchidWithdrawFundsAndEscrow
} from "../api/orchid-eth";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionResult} from "./TransactionResult";
import {SubmitButton} from "./SubmitButton";
import {Address} from "../api/orchid-types";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class WithdrawFunds extends Component {

  state = {
    potBalance: null as BigInt | null,
    withdrawAmount: null as number | null,
    withdrawAll: false,
    sendToAddress: null as Address | null,
    amountError: true,
    addressError: true,
    // tx
    running: false,
    text: "",
    txId: "",
  };
  amountInput = React.createRef<HTMLInputElement>();

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    api.lotteryPot_wait.subscribe(pot => {
      this.setState({potBalance: pot.balance})
    });
  }

  async submitWithdrawFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    const withdrawAmount = this.state.withdrawAmount;
    const withdrawAll = this.state.withdrawAll;
    const sendToAddress = this.state.sendToAddress;

    if (account == null
        || withdrawAmount == null
        || withdrawAll == null
        || sendToAddress == null
    ) {
      return;
    }
    this.setState({running: true});

    try {
      let txId;
      if (this.state.withdrawAll) {
        txId = await orchidWithdrawFundsAndEscrow(sendToAddress);
      } else {
        const withdrawWei = oxtToWeiString(withdrawAmount);
        txId = await orchidWithdrawFunds(sendToAddress, withdrawWei);
      }
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
    let withdrawAmount = this.state.withdrawAll ?
          weiToOxtString(this.state.potBalance || BigInt(0), 4) :
          this.state.withdrawAmount;

    let api = OrchidAPI.shared();
    let submitEnabled = api.account.value !== null
        && this.state.sendToAddress !== null
        && (this.state.withdrawAll || this.state.withdrawAmount !== null);

    let currentInputAmount = this.amountInput.current == null ? "" : this.amountInput.current.value;
    return (
        <div>
          <label className="title">Withdraw Funds</label>
          <p className="instructions">
            Funds may be withdrawn from your lottery pot balance at any time,
            however if an overdraft occurs due to an outstanding lottery ticket your escrow
            will be lost. Please be sure that this account is not active before withdrawing funds.
            To withdraw your full balance including the escrow the account must be unlocked.
          </p>

          <label>Available Lottery Pot Balance Amount</label>
          <input
              value={this.state.potBalance == null ? "" : weiToOxtString(this.state.potBalance, 4)}
              type="number" className="pot-balance" placeholder="Amount in OXT" readOnly/>

          <label>Withdraw Amount<span className={errorClass(this.state.amountError)}> *</span></label>
          <input
              ref={this.amountInput}
              type="number"
              className="withdraw-amount editable"
              placeholder="Amount in OXT"
              value={withdrawAmount == null ? currentInputAmount : withdrawAmount}
              onChange={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                const valid = amount != null && amount > 0
                    && (this.state.potBalance == null || oxtToWei(amount) <= this.state.potBalance);
                this.setState({
                  withdrawAmount: amount,
                  amountError: !valid
                });
              }}
          />

          <label>To Address<span className={errorClass(this.state.addressError)}> *</span></label>
          <input
              type="text"
              className="send-to-address editable"
              placeholder="Address"
              onChange={(e) => {
                const address = e.currentTarget.value;
                const valid = isEthAddress(address);
                this.setState({
                  sendToAddress: valid ? address : null,
                  addressError: !valid
                });
              }}
          />

          <div style={{display: 'flex', alignItems: 'baseline', opacity: 0.3, pointerEvents: "none"}}>
            <input
                type="checkbox"
                style={{transform: 'scale(2)', margin: '16px'}}
                onChange={(e) => {
                  const value = e.currentTarget.checked;
                  this.setState({withdrawAll: value});
                }}
            />
            <label>Withdraw Full Balance and Escrow</label>
          </div>

          <div style={{marginTop: '16px'}} className="submit-button">
            <SubmitButton onClick={() => this.submitWithdrawFunds().then()} enabled={submitEnabled}/>
          </div>

          <TransactionResult
              running={this.state.running}
              text={this.state.text}
              txId={this.state.txId}
          />
        </div>
    );
  }
}

