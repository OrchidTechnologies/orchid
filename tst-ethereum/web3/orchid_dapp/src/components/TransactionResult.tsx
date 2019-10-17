import React from "react";
import {EtherscanIO} from "../api/etherscan-io";

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
export function TransactionResult(props: {
  running?: boolean, text?: string, txId?: string
}) {
  return (
    <div className="transaction-result">
      <div style={{marginBottom: '8px'}}
           className={["spinner", props.running ? "" : "hidden"].join(" ")}/>
      <div style={{marginTop: '8px', overflowX: 'hidden'}}
           className={[!(props.running) ? "" : "hidden"].join(" ")}>
        <span style={{fontSize: '18pt'}}>{props.text || ""}</span>
        <br/>
        <span>
        <a target="_blank" rel="noopener noreferrer"
           href={EtherscanIO.txLink(props.txId || "")}
           style={{fontSize: '18pt', color: 'rebeccapurple'}}>{props.txId}</a>
        </span>
      </div>
    </div>
  );
}


