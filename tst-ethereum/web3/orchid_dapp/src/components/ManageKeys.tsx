import React, {Component} from "react";
import './ManageKeys.css'
import {errorClass} from "../util/util";
import {isEthAddress, orchidBindSigner} from "../api/orchid-eth";
import {Address} from "../api/orchid-types";
import {OrchidAPI} from "../api/orchid-api";
import {SubmitButton} from "./SubmitButton";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {Container} from "react-bootstrap";

export class ManageKeys extends Component {

  state = {
    signerAddress: null as Address | null,
    addressError: true,
    tx: new TransactionStatus()
  };

  private async submitSigner() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    const signer = this.state.signerAddress;
    if (account == null || signer == null) {
      return;
    }
    this.setState({tx: TransactionStatus.running()});

    try {
      let txId = await orchidBindSigner(signer);
      this.setState({tx: TransactionStatus.result("Transaction Complete!", txId)});
    } catch (err) {
      this.setState({tx: TransactionStatus.error(`Transaction Failed: ${err}`)});
    }
  }

  render() {
    let api = OrchidAPI.shared();
    let submitEnabled = api.account.value !== null && this.state.signerAddress !== null;
    return (
        <Container className="form-style">
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
                this.setState({
                  signerAddress: valid ? address : null,
                  addressError: !valid
                });
              }}
          />
          <div style={{marginTop: '16px'}} className="submit-button">
            <SubmitButton onClick={() => this.submitSigner().then()} enabled={submitEnabled}/>
          </div>
          <TransactionProgress /*ref={txResult}*/ tx={this.state.tx}/>
        </Container>
    );
  }
}

