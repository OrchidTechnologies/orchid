import React, {Component} from "react";
import './ManageKeys.css'
import {errorClass} from "../util/util";
import {isEthAddress, orchidMoveFundsToEscrow, orchidBindSigner, oxtToWeiString, weiToOxtString} from "../api/orchid-eth";
import {BehaviorSubject, combineLatest} from "rxjs";
import {Address} from "../api/orchid-types";
import {map} from "rxjs/operators";
import {OrchidAPI} from "../api/orchid-api";
import {SubmitButton} from "./SubmitButton";
import {TransactionResult} from "./TransactionResult";

export class ManageKeys extends Component {
  signerAddress = new BehaviorSubject<Address | null>(null);

  formValid = combineLatest([this.signerAddress])
      .pipe(map(val => {
        const [signerAddress] = val;
        let api = OrchidAPI.shared();
        return api.account.value !== null && signerAddress !== null;
      }));

  state = {
    formValid: false,
    running: false,
    text: "",
    txId: "",
    addressError: true
  };

  componentDidMount(): void {
    this.formValid.subscribe(valid => {
      this.setState({formValid: valid});
    });
  }

  private async submitSigner() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    const signer = this.signerAddress.value;
    if (account == null || signer == null) {
      return;
    }
    this.setState({
      formValid: false,
      running: true
    });

    try {
      let txId = await orchidBindSigner(signer);
      this.setState({
        text: "Transaction Complete!",
        txId: txId,
        running: false,
        formValid: true
      });
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
          <label className="title">Manage Keys</label>
          <p className="instructions">
            Bind signer keys to connect Orchid client applications to your Lottery Pot.
            If you lose your signer key you can replace it with a new one but signer keys cannot
            currently be revoked.
          </p>

          {/*<img width="192" className="ManageKeys-qrcode"*/}
          {/*     src="https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl=0x8CCF9C4a7674D5784831b5E1237d9eC9Dddf9d7F&choe=UTF-8"*/}
          {/*     alt=""/>*/}

          <label>Signer Address<span className={errorClass(this.state.addressError)}> *</span></label>
          <input
              type="text"
              className="editable"
              placeholder="Address"
              onChange={(e) => {
                const address = e.currentTarget.value;
                const valid = isEthAddress(address);
                this.setState({addressError: !valid});
                this.signerAddress.next(valid ? address : null);
              }}
          />

          <div style={{marginTop: '16px'}} className="submit-button">
            <SubmitButton onClick={() => this.submitSigner().then()}
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

