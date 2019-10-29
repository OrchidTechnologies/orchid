import React, {FC, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {orchidAddFunds, oxtToWeiString} from "../api/orchid-eth";
import {Divider, errorClass, parseFloatSafe} from "../util/util";
import {TxProps, TxResult} from "./TxResult";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'

interface AddFundsProps {
  defaultAddAmount?: number
  defaultAddEscrow?: number
}

export const AddFunds: FC<AddFundsProps> = (props) => {
  const [addAmount, setAddAmount] = useState<number | null>(null);
  const [addEscrow, setAddEscrow] = useState<number | null>(0);
  const [amountError, setAmountError] = useState(true);
  const [escrowError, setEscrowError] = useState(false);
  const [tx, setTx] = useState(new TxProps());
  const txResult = React.createRef<TxResult>();

  async function submitAddFunds() {
    let api = OrchidAPI.shared();
    let account = api.account.value;
    console.log("submit add funds: ", account, addAmount, addEscrow);
    if (account == null
      || addAmount == null
      || addEscrow == null) {
      return;
    }

    setTx(TxProps.running());
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    try {
      const amountWei = oxtToWeiString(addAmount);
      const escrowWei = oxtToWeiString(addEscrow);
      let potAddress = account.address;

      let txId = await orchidAddFunds(potAddress, amountWei, escrowWei);
      setTx(TxProps.result("Transaction Complete!", txId));

      api.updateAccount().then();
      api.updateTransactions().then();
    } catch (err) {
      setTx(TxProps.error(`Transaction Failed: ${err}`));
    }
  }

  let submitEnabled =
    OrchidAPI.shared().account.value !== null
    && !tx.running
    && !amountError
    && !escrowError;

  return (
    <Container className="form-style">
      <label className="title">Add Funds</label>

      {/*Balance*/}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>Add to Balance<span
            className={errorClass(amountError)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onChange={(e) => {
              let amount = parseFloatSafe(e.currentTarget.value);
              setAddAmount(amount);
              setAmountError(amount == null);
            }}
            type="number"
            placeholder="0.00"
            defaultValue={props.defaultAddAmount}
          />
        </Col>
      </Row>

      {/*Deposit*/}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>Add to Deposit<span
            className={errorClass(escrowError)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onInput={(e) => {
              let amount = parseFloatSafe(e.currentTarget.value);
              setAddEscrow(amount);
              setEscrowError(amount == null);
            }}
            type="number" placeholder="0.00"
            defaultValue={props.defaultAddEscrow}
          />
        </Col>
      </Row>

      <p className="instructions">
        Your deposit secures access to the Orchid network and demonstrates authenticity to
        bandwidth sellers.
      </p>
      <Divider noGutters={true}/>

      {/*Total*/}
      <Row className="total-row" noGutters={true}>
        <Col>
          <label>Total</label>
        </Col>
        <Col>
          <div className="oxt-1">{
            ((addEscrow||0)+(addAmount||0)).toFixed(2)
          } OXT</div>
        </Col>
      </Row>

      <SubmitButton onClick={() => submitAddFunds()} enabled={submitEnabled}>
        Add OXT
      </SubmitButton>

      <TxResult ref={txResult} tx={tx}/>
    </Container>
  );
};


