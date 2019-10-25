import React, {Component} from "react";
import {EtherscanIO} from "../api/etherscan-io";
import {findDOMNode} from "react-dom";

export interface TxState {
  running: boolean,
  result: string,
  txId: string
}

export function TxResult(props: { txState: TxState }) {
  return (
      <div className="transaction-result">
        <div style={{marginBottom: '8px'}}
             className={["spinner", props.txState.running ? "" : "hidden"].join(" ")}/>
        <div style={{marginTop: '8px', overflowX: 'hidden'}}
             className={[!(props.txState.running) ? "" : "hidden"].join(" ")}>
          <span style={{fontSize: '18pt'}}>{props.txState.result}</span>
          <br/>
          <span>
        <a target="_blank" rel="noopener noreferrer"
           href={EtherscanIO.txLink(props.txState.txId)}
           style={{fontSize: '18pt', color: 'rebeccapurple'}}>{props.txState.txId}</a>
        </span>
        </div>
      </div>
  );
}

// TODO:
export class TransactionResult extends Component<{
  running?: boolean, text?: string, txId?: string
}> {
  render() {
    return (
      <div className="transaction-result">
        <div style={{marginBottom: '8px'}}
             className={["spinner", this.props.running ? "" : "hidden"].join(" ")}/>
        <div style={{marginTop: '8px', overflowX: 'hidden'}}
             className={[!(this.props.running) ? "" : "hidden"].join(" ")}>
          <span style={{fontSize: '18pt'}}>{this.props.text || ""}</span>
          <br/>
          <span>
        <a target="_blank" rel="noopener noreferrer"
           href={EtherscanIO.txLink(this.props.txId || "")}
           style={{fontSize: '18pt', color: 'rebeccapurple'}}>{this.props.txId}</a>
        </span>
        </div>
      </div>
    );
  }

  scrollIntoView() {
    (findDOMNode(this) as HTMLDivElement).scrollIntoView();
  }
}


