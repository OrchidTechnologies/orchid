import React, {Component} from "react";
import {EtherscanIO} from "../api/etherscan-io";
import {findDOMNode} from "react-dom";

export class TxProps {
  running = false;
  result = "";
  txId = "";

  static running(): TxProps {
    return {
      running: true,
      result: "",
      txId: ""
    };
  }
  static result(text: string = "", txId: string = ""): TxProps {
    return {
      running: false,
      result: text,
      txId: txId
    };
  }

  static error(error: string): TxProps {
    return {
      running: false,
      result: error,
      txId: ""
    };
  }
}

export class TxResult extends Component<{tx: TxProps}> {
  render() {
    let {result, running, txId} = this.props.tx;
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


