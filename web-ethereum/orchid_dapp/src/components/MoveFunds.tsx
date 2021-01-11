import React, {Component, useContext} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {errorClass, parseFloatSafe} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Container} from "react-bootstrap";
import {S} from "../i18n/S";
import {Subscription} from "rxjs";
import {LotFunds} from "../api/orchid-eth-token-types";
import {WalletProviderContext} from "../index";
import {WalletProviderStatus} from "../api/orchid-eth-web3";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export function MoveFunds() {
  let walletContext: WalletProviderStatus = useContext(WalletProviderContext);
  return <MoveFundsImpl walletContext={walletContext}/>
};

export class MoveFundsImpl extends Component<{
  walletContext: WalletProviderStatus
}, {
  potBalance: LotFunds | null;
  amountError: boolean;
  tx: TransactionStatus;
  moveAmount: number | null
}> {
  state = {
    moveAmount: null as number | null,
    amountError: true,
    potBalance: null as LotFunds | null,
    tx: new TransactionStatus()
  };
  subscriptions: Subscription [] = [];

  componentDidMount(): void {
    let api = OrchidAPI.shared();
    this.subscriptions.push(
      api.lotteryPot.subscribe(pot => {
        this.setState(current => ({...current, potBalance: pot?.balance ?? null}));
      }));
  }

  componentWillUnmount(): void {
    this.subscriptions.forEach(sub => {
      sub.unsubscribe()
    })
  }

  async submitMoveFunds() {
    let api = OrchidAPI.shared();
    let {fundsToken: funds} = this.props.walletContext;
    if (!api.eth || !funds) { return }
    let wallet = api.wallet.value;
    let signer = api.signer.value;
    if (!wallet || !signer
      || this.state.moveAmount == null
      || this.state.potBalance == null
    ) {
      return;
    }
    this.setState(current => ({...current, tx: TransactionStatus.running()}));

    try {
      const moveEscrow = funds.fromNumber(this.state.moveAmount);
      let txId = await api.eth.orchidMoveFundsToEscrow(
        wallet.address, signer.address, moveEscrow, this.state.potBalance);
      await api.updateLotteryPot();
      this.setState(current => ({
        ...current,
        tx: TransactionStatus.result(txId, S.transactionComplete)
      }));
    } catch (err) {
      this.setState(current => ({
        ...current,
        tx: TransactionStatus.error(`${S.transactionFailed}: ${err}`)
      }));
    }
  }

  render() {
    let api = OrchidAPI.shared();
    let {fundsToken: funds} = this.props.walletContext;
    let submitEnabled = api.wallet.value !== null
      && !this.state.tx.isRunning
      && this.state.moveAmount != null
      && funds != null
      && funds.fromNumber(this.state.moveAmount).lte(this.state.potBalance ?? funds.zero)

    let amountText = "Amount in " + (funds?.symbol ?? "Funds");
    return (
      <Container className="form-style">
        <label className="title">{S.moveFunds}</label>
        <p className="instructions">
          {S.moveFundsFromYourLotteryPot + "  "}
          {S.balanceFundsAreUsedByOrchid + "  "}
          {S.depositFundsAreRequiredToParticipate}
        </p>
        <label>{S.availableLotteryPotBalance}</label>
        <input type="number" className="pot-balance"
               placeholder={amountText}
               value={this.state.potBalance == null ? "" : this.state.potBalance.toFixedLocalized(4)}
               readOnly/>
        <label>{S.moveToDepositAmount}<span className={errorClass(this.state.amountError)}> *</span></label>
        <input
          type="number"
          placeholder={amountText}
          className="editable"
          onInput={(e) => {
            let amount = parseFloatSafe(e.currentTarget.value);
            const valid = amount != null && amount > 0
              && (this.state.potBalance == null || funds?.fromNumber(amount).lte(this.state.potBalance));
            this.setState(current => ({
              ...current,
              moveAmount: amount,
              amountError: !valid
            }));
          }}
        />
        <SubmitButton onClick={() => this.submitMoveFunds().then()} enabled={submitEnabled}/>
        <TransactionProgress tx={this.state.tx}/>
      </Container>
    );
  }
}

