import React, {Component} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {BehaviorSubject, combineLatest} from "rxjs";
import {map} from "rxjs/operators";
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

export class WithdrawFunds extends Component {

  withdrawAmount = new BehaviorSubject<number | null>(null);
  withdrawAll = new BehaviorSubject(false);
  sendToAddress = new BehaviorSubject<Address | null>(null);

  formValid = combineLatest([this.withdrawAmount, this.withdrawAll, this.sendToAddress])
      .pipe(map(val => {
        const [withdrawAmount, withdrawAll, sendToAddress] = val;
        this.setState({
          withdrawAll: withdrawAll,
          withdrawAmount: withdrawAll ? weiToOxtString(this.state.potBalance || BigInt(0), 4) : withdrawAmount
        });
        let api = OrchidAPI.shared();
        return api.account.value !== null
            && sendToAddress !== null
            && (withdrawAll || withdrawAmount !== null)
      }));

  state = {
    potBalance: null as BigInt | null,
    withdrawAll: false,
    withdrawAmount: null as number | null,
    formValid: false,
    running: false,
    text: "",
    txId: "",
    amountError: true,
    addressError: true
  };

  componentDidMount(): void {
    let api = OrchidAPI.shared();

    this.formValid.subscribe(valid => {
      this.setState({formValid: valid});
    });

    api.lotteryPot_wait.subscribe(pot => {
      this.setState({potBalance: pot.balance})
    });
  }

  async submitWithdrawFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    const withdrawAmount = this.withdrawAmount.value;
    const withdrawAll = this.withdrawAll.value;
    const sendToAddress = this.sendToAddress.value;

    if (account == null
        || withdrawAmount == null
        || withdrawAll == null
        || sendToAddress == null
    ) {
      return;
    }
    this.setState({
      formValid: false,
      running: true
    });

    try {
      let txId;
      if (this.withdrawAll.value) {
        txId = await orchidWithdrawFundsAndEscrow(sendToAddress);
      } else {
        const withdrawWei = oxtToWeiString(withdrawAmount);
        txId = await orchidWithdrawFunds(sendToAddress, withdrawWei);
      }
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
              type="number"
              className="withdraw-amount editable"
              placeholder="Amount in OXT"
              value={
                this.state.withdrawAmount == null ? "" : this.state.withdrawAmount
              }
              onChange={(e) => {
                let amount = parseFloatSafe(e.currentTarget.value);
                const valid = amount != null && amount > BigInt(0)
                    && (this.state.potBalance == null || oxtToWei(amount) <= this.state.potBalance);
                this.setState({amountError: !valid});
                this.withdrawAmount.next(valid ? amount : null);
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
                this.setState({addressError: !valid});
                this.sendToAddress.next(valid ? address : null);
              }}
          />

          <div style={{display: 'flex', alignItems: 'baseline', opacity: 0.3, pointerEvents: "none"}}>
            <input
                type="checkbox"
                style={{transform: 'scale(2)', margin: '16px'}}
                onChange={(e) => {
                  const value = e.currentTarget.checked;
                  this.withdrawAll.next(value);
                }}
            />
            <label>Withdraw Full Balance and Escrow</label>
          </div>

          <div style={{marginTop: '16px'}} className="submit-button">
            <SubmitButton onClick={() => this.submitWithdrawFunds().then()}
                          enabled={this.state.formValid}/>
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

