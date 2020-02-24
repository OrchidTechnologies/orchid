import React, {useState} from "react";
import {
  EthereumTransactionStatus,
  OrchidTransactionDetail,
  OrchidTransactionType
} from "../api/orchid-tx";
import {Col, Collapse, Container, Row} from "react-bootstrap";
import {OrchidAPI} from "../api/orchid-api";
import {S} from "../i18n/S";

export const TransactionPanel: React.FC<{
  tx: OrchidTransactionDetail
}> = (props) => {
  const [open, setOpen] = useState(false);

  let running = props.tx.status === EthereumTransactionStatus.PENDING;
  let type: string = "";
  switch (props.tx.type) {
    case OrchidTransactionType.AddFunds:
      type = S.addFunds;
      break;
    case OrchidTransactionType.StakeFunds:
      type = S.stakeFunds;
      break;
    case OrchidTransactionType.WithdrawFunds:
      type = S.withdrawFunds;
      break;
    case OrchidTransactionType.Lock:
      type = S.lock;
      break;
    case OrchidTransactionType.Unlock:
      type = S.unlock;
      break;
    case OrchidTransactionType.MoveFundsToEscrow:
      type = S.moveFundsToDeposit;
      break;
    case OrchidTransactionType.Reset:
      type = S.resetAccount;
      break;
  }

  let status: string = "";
  switch(props.tx.status) {
    case EthereumTransactionStatus.PENDING:
      status = S.pending;
      break;
    case EthereumTransactionStatus.SUCCESS:
      status = S.complete;
      break;
    case EthereumTransactionStatus.FAILURE:
      status = S.failed;
      break;

  }

  let multiple = props.tx.transactions.length > 1;
  if (multiple) {
    type = type + ` (${props.tx.transactions.length})`;
  }

  let ethTxs = props.tx.transactions.map(tx => {

    let statusTerm: string = "";
    switch(tx.status) {
      case EthereumTransactionStatus.PENDING:
        statusTerm = S.pending;
        break;
      case EthereumTransactionStatus.SUCCESS:
        statusTerm = S.complete;
        break;
      case EthereumTransactionStatus.FAILURE:
        statusTerm = S.failed;
        break;
    }

    let status = multiple ?
      (<Row style={{marginTop: '4px'}}><Col>{S.status}: { statusTerm }</Col></Row>) : "";

    return <Row key={tx.hash}>
      <Col style={{marginTop: '0px'}}>
        <hr style={{borderColor: "grey"}}/>
        <Row style={{}}>
          <Col style={{
            fontSize: '14px', textOverflow: "ellipsis", overflowX: 'hidden',
            whiteSpace: 'nowrap',
          }}>
            {S.hash}: {tx.hash}
          </Col>
        </Row>
        <Row>
          <Col
            style={{
              fontStyle: 'italic', fontSize: '14px', textOverflow: "ellipsis",
              whiteSpace: 'nowrap',
            }}>
            <a style={{color: "lightblue"}} href={tx.getLink()}>{S.viewOnBlockchain}</a>
          </Col>
        </Row>
        {status}
        <Row>
          <Col style={{marginTop: '2px'}}>
            {S.confirmations}: {tx.confirmations}
          </Col>
        </Row>
      </Col>
    </Row>
  });

  function dismiss() {
    OrchidAPI.shared().transactionMonitor.remove(props.tx.hash);
  }

  return (
    <Container
      style={{
        color: "white",
        backgroundColor: "#5f45ba",
        width: "100%",
        padding: "12px",
        paddingLeft: '24px',
        paddingRight: '24px',
      }}
    >
      <Row onClick={() => { setOpen(!open) }} >
        <Col style={{
          flexGrow: 0,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          paddingRight: 0
        }}>
          <div style={{fontSize: '16px', width: '5px'}}>{open ? "▾" : "▸"}</div>
        </Col>
        <Col>
          <span>{S.transaction} {status}</span>
          <div style={{fontStyle: 'italic', fontSize: '14px',}}>{type}</div>
        </Col>
        <Col
          style={{
            flexGrow: 0,
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            paddingRight: '0px',
          }}
        >
          <div
            className={["spinner-small", running ? "" : "hidden"].join(" ")}/>
        </Col>
        <Col style={{
          flexGrow: 0,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
        }}
          onClick={() => dismiss()}
        >
          <div>×</div>
        </Col>
      </Row>
      <Collapse in={open}>
        <Row style={{marginTop: '0px', marginBottom: '8px'}}>
          <Col>
            {ethTxs}
          </Col>
        </Row>
      </Collapse>
    </Container>
  );
};


