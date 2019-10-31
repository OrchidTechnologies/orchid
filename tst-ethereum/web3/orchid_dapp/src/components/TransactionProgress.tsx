import React, {Component} from "react";
import {EtherscanIO} from "../api/etherscan-io";
import {findDOMNode} from "react-dom";

enum TransactionState {
  New, Running, Completed, Failed
}

export class TransactionStatus {
  state: TransactionState;
  result: string | null;
  txId: string | null;

  constructor(
    state: TransactionState = TransactionState.New,
    result: string = "",
    txId: string|null = null)
  {
    this.state = state;
    this.result = result;
    this.txId = txId;
  }

  isRunning(): boolean {
    return this.state === TransactionState.Running;
  }

  static running(txId?: string): TransactionStatus {
    return new TransactionStatus(
      TransactionState.Running,
      "",
      txId || "");
  }

  static result(txId: string, text: string = ""): TransactionStatus {
    return new TransactionStatus(
      TransactionState.Completed,
      text,
      txId);
  }

  static error(error: string): TransactionStatus {
    return new TransactionStatus(
      TransactionState.Failed,
      error,
      "");
  }
}

export class TransactionProgress extends Component<{ tx: TransactionStatus }> {
  render() {
    let {result, state, txId} = this.props.tx;
    let running = state === TransactionState.Running;
    return (
      <div className="transaction-result">
        <div style={{marginBottom: '8px'}}
             className={["spinner", running ? "" : "hidden"].join(" ")}/>
        <div style={{marginTop: '8px', overflowX: 'hidden'}}
             className={[!running ? "" : "hidden"].join(" ")}>
          <span style={{fontSize: '18pt'}}>{result || ""}</span>
          <br/>
          <span>
        <a target="_blank" rel="noopener noreferrer"
           href={EtherscanIO.txLink(txId || "")}
           style={{fontSize: '18pt', color: 'rebeccapurple'}}>{txId}</a>
        </span>
        </div>
      </div>
    );
  }

  scrollIntoView() {
    (findDOMNode(this) as HTMLDivElement).scrollIntoView();
  }
}


