import React, {FC, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {
  isEthAddress, orchidAddFunds, oxtToWei, weiToOxtString
} from "../api/orchid-eth";
import {Divider, errorClass, parseFloatSafe, Visibility} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'
import {Address} from "../api/orchid-types";
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

interface AddFundsProps {
  createAccount: boolean
  defaultAddAmount?: number
  defaultAddEscrow?: number
}

export const AddFunds: FC<AddFundsProps> = (props) => {

  // Create account state
  const [newSignerAddress, setNewSignerAddress] = useState<Address | null>(null);
  const [signerKeyError, setSignerKeyError] = useState(true);

  // Add funds state
  const [addAmount, setAddAmount] = useState<number | null>(null);
  const [addEscrow, setAddEscrow] = useState<number | null>(0);
  const [amountError, setAmountError] = useState(true);
  const [escrowError, setEscrowError] = useState(false);
  const [tx, setTx] = useState(new TransactionStatus());
  const txResult = React.createRef<TransactionProgress>();
  const [walletBalance, setWalletBalance] = useState<BigInt | null>(null);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletSubscription = api.wallet_wait.subscribe(wallet => {
      console.log("add funds got wallet: ", wallet);
      setWalletBalance(wallet.oxtBalance);
    });
    return () => {
      walletSubscription.unsubscribe();
    };
  }, []);

  async function submitAddFunds() {
    let api = OrchidAPI.shared();
    let walletAddress = api.wallet.value ? api.wallet.value.address : null;
    console.log("submit add funds: ", walletAddress, addAmount, addEscrow);
    let signerAddress = props.createAccount ? newSignerAddress :
      (api.signer.value ? api.signer.value.address : null);
    if (walletAddress == null || signerAddress == null || addAmount == null || addEscrow == null) {
      return;
    }

    setTx(TransactionStatus.running());
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    try {
      const amountWei = oxtToWei(addAmount);
      const escrowWei = oxtToWei(addEscrow);

      let txId = await orchidAddFunds(walletAddress, signerAddress, amountWei, escrowWei);
      if (props.createAccount) {
        await api.updateSigners();
      } else {
        await api.updateLotteryPot();
      }
      setTx(TransactionStatus.result(txId, "Transaction Complete!"));
      api.updateWallet().then();
      api.updateTransactions().then();
    } catch (err) {
      setTx(TransactionStatus.error(`Transaction Failed: ${err}`));
    }
  }

  let submitEnabled =
    OrchidAPI.shared().wallet.value !== null
    && !tx.isRunning()
    && (!props.createAccount || !signerKeyError)
    && !amountError
    && !escrowError;

  return (
    <Container className="form-style">
      <label className="title">{props.createAccount ? "Create New Account" : "Add Funds"}</label>

      {/*Available Wallet Balance*/}
      <Row className="form-row">
        <Col>
          <label>From Available</label>
        </Col>
        <Col>
          <div className="oxt-1-pad">
            {walletBalance == null ? "..." : weiToOxtString(walletBalance, 2)}
          </div>
        </Col>
      </Row>

      {/*New Account Signer Address*/}
      <Visibility visible={props.createAccount}>
        <Row className="form-row" noGutters={true}>
          <Col>
            <label>Signer Key<span
              className={errorClass(signerKeyError)}> *</span></label>
          </Col>
          <Col>
            <input
              className="send-to-address editable"
              type="text"
              placeholder="Address"
              onChange={(e) => {
                const address = e.currentTarget.value;
                const valid = isEthAddress(address);
                setNewSignerAddress(valid ? address : null);
                setSignerKeyError(!valid);
              }}
            />
          </Col>
        </Row>
      </Visibility>

      {/*Add to Balance*/}
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
              setAmountError(amount == null || oxtToWei(amount) > (walletBalance || 0));
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
            ((addEscrow || 0) + (addAmount || 0)).toFixed(2)
          } OXT
          </div>
        </Col>
      </Row>

      <SubmitButton onClick={() => submitAddFunds()} enabled={submitEnabled}>
        {props.createAccount ? "Create Account" : "Add OXT"}
      </SubmitButton>

      <TransactionProgress ref={txResult} tx={tx}/>
    </Container>
  );
};


