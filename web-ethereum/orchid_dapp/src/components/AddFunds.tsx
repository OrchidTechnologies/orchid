import React, {FC, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {Divider, errorClass, parseFloatSafe, Visibility} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'
import {Address, GWEI} from "../api/orchid-types";
import {GasPricingStrategy, isEthAddress, keikiToOxtString, oxtToKeiki} from "../api/orchid-eth";
import {OrchidContracts} from "../api/orchid-eth-contracts";
import {S} from "../i18n/S";

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
  const [amountError, setAmountError] = useState(false);
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
    let wallet = api.wallet.value;
    if (!wallet) {
      return;
    }
    let walletAddress = wallet.address;
    console.log("submit add funds: ", walletAddress, addAmount, addEscrow);
    let signerAddress = props.createAccount ? newSignerAddress :
      (api.signer.value ? api.signer.value.address : null);
    if (walletAddress == null || signerAddress == null) {
      return;
    }
    if (props.createAccount && (addAmount == null || addEscrow == null)) {
      return;
    }

    setTx(TransactionStatus.running());
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    try {
      const amountWei = oxtToKeiki(addAmount || 0);
      const escrowWei = oxtToKeiki(addEscrow || 0 );

      // Choose a gas price
      let medianGasPrice: GWEI = await api.eth.getGasPrice();
      let gasPrice = GasPricingStrategy.chooseGasPrice(
        OrchidContracts.add_funds_total_max_gas, medianGasPrice, wallet.ethBalance);
      if (!gasPrice) {
        console.log("Add funds: gas price potentially too low.");
      }

      let txId = await api.eth.orchidAddFunds(walletAddress, signerAddress, amountWei, escrowWei, gasPrice);
      if (props.createAccount) {
        await api.updateSigners();
      } else {
        await api.updateLotteryPot();
      }
      setTx(TransactionStatus.result(txId, S.transactionComplete));
      api.updateWallet().then();
      api.updateTransactions().then();
    } catch (err) {
      setTx(TransactionStatus.error(`${S.transactionFailed}: ${err}`));
      throw err
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
      <label className="title">{props.createAccount ? S.createNewAccount : S.addFunds}</label>

      {/*Available Wallet Balance*/}
      <Row className="form-row">
        <Col>
          <label>{S.fromAvailable}</label>
        </Col>
        <Col>
          <div className="oxt-1-pad">
            {walletBalance == null ? "..." : keikiToOxtString(walletBalance, 2)}
          </div>
        </Col>
      </Row>

      {/*New Account Signer Address*/}
      <Visibility visible={props.createAccount}>
        <Row className="form-row" noGutters={true}>
          <Col>
            <label>{S.signerKey}<span
              className={errorClass(signerKeyError)}> *</span></label>
          </Col>
          <Col>
            <input
              className="send-to-address editable"
              type="text"
              placeholder={S.address}
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
          <label>{S.addToBalance}<span
            className={errorClass(amountError && props.createAccount)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onChange={(e) => {
              let amount = parseFloatSafe(e.currentTarget.value);
              setAddAmount(amount);
              if (props.createAccount) {
                setAmountError(amount == null || oxtToKeiki(amount) > (walletBalance || 0));
              }
            }}
            type="number"
            placeholder={(0).toFixedLocalized(2)}
            defaultValue={props.defaultAddAmount}
          />
        </Col>
      </Row>

      {/*Deposit*/}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>{S.addToDeposit}<span className={errorClass(escrowError && props.createAccount)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onInput={(e) => {
              let amount = parseFloatSafe(e.currentTarget.value);
              setAddEscrow(amount);
              if (props.createAccount) {
                setEscrowError(amount == null);
              }
            }}
            type="number"
            placeholder={(0).toFixedLocalized(2)}
            defaultValue={props.defaultAddEscrow}
          />
        </Col>
      </Row>

      <p className="instructions">
        {S.yourDepositSecuresAccessInstruction}
      </p>
      <Divider noGutters={true}/>

      {/*Total*/}
      <Row className="total-row" noGutters={true}>
        <Col>
          <label>{S.total}</label>
        </Col>
        <Col>
          <div className="oxt-1">{
            ((addEscrow || 0) + (addAmount || 0)).toFixedLocalized(2)
          } OXT
          </div>
        </Col>
      </Row>

      <SubmitButton onClick={() => submitAddFunds()} enabled={submitEnabled}>
        {props.createAccount ? S.createAccount : S.addOXT}
      </SubmitButton>

      <TransactionProgress ref={txResult} tx={tx}/>
    </Container>
  );
};


