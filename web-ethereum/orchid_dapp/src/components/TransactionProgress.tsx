import React, {Component} from "react";
import {EtherscanIO} from "../api/etherscan-io";
import {findDOMNode} from "react-dom";
import {Visibility} from "../util/util";
import {Signer} from "../api/orchid-eth";
import {AccountQRCode} from "./AccountQRCode";
import {TransactionId} from "../api/orchid-eth-types";

export enum TransactionState {
  New, Running, Completed, Failed
}

export class TransactionStatus {
  state: TransactionState;
  result: string | null;
  txId: string | null;
  signer: Signer | null;

  constructor(
    state: TransactionState = TransactionState.New,
    result: string = "",
    txId: string | null = null,
    signer: Signer | null = null
  ) {
    this.state = state;
    this.result = result;
    this.txId = txId;
    this.signer = signer;
  }

  get isRunning(): boolean {
    return this.state === TransactionState.Running;
  }

  static running(txId?: string): TransactionStatus {
    return new TransactionStatus(
      TransactionState.Running,
      "",
      txId || "");
  }

  static result(txId: TransactionId, text: string = "", signer: Signer | null = null): TransactionStatus {
    return new TransactionStatus(
      TransactionState.Completed, text, txId, signer);
  }

  static error(error: string): TransactionStatus {
    return new TransactionStatus(
      TransactionState.Failed,
      error,
      "");
  }
}

// Note: this is a component to support the `scrollIntoView` method.
export class TransactionProgress extends Component<any, { tx: TransactionStatus }> {

  render() {
    let {result, state, txId, signer} = this.props.tx;
    let running = state === TransactionState.Running;
    return (
      <div className="transaction-result">
        {/*Show the spinner when running.*/}
        {/*<div style={{marginBottom: '8px'}}*/}
        {/*     className={["spinner", running ? "" : "hidden"].join(" ")}/>*/}
        <div
          style={{
            marginTop: '8px', overflowX: 'hidden', textOverflow: "ellipsis"
          }}
          className={[!running ? "" : "hidden"].join(" ")}>
          <span style={{fontSize: '18pt'}}>{result || ""}</span>
          <br/>
          <span>
            <a target="_blank" rel="noopener noreferrer"
               href={EtherscanIO.txLink(txId || "")}
               style={{fontSize: '18pt', color: 'rebeccapurple'}}>{txId}</a>
          </span>
        </div>
        {/*account QR Code*/}
        <Visibility visible={signer != null}>
          <AccountQRCode data={signer != null ? signer.toConfigString() : ""}/>
        </Visibility>
      </div>
    );
  }

  scrollIntoView() {
    (findDOMNode(this) as HTMLDivElement).scrollIntoView();
  }
}


