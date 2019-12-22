import React, {useContext, useEffect, useState} from "react";
import {Col, Container, Modal, Row} from "react-bootstrap";
import {SubmitButton} from "../SubmitButton";
import {Route, RouteContext} from "../Route";
import {OverviewLoading, OverviewProps} from "./Overview";
import {
  isEthAddress,
  keikiToOxt,
  keikiToOxtString,
  orchidAddFunds,
  oxtToKeiki
} from "../../api/orchid-eth";
import {Divider, errorClass, Visibility} from "../../util/util";
import './Overview.css';
import {Address} from "../../api/orchid-types";
import {OrchidAPI} from "../../api/orchid-api";
import {TransactionProgress, TransactionState, TransactionStatus} from "../TransactionProgress";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const OverviewQuickSetup: React.FC<OverviewProps> = (props) => {

  // Preconditions
  let {noAccount, potFunded, walletEthEmpty, walletOxtEmpty} = props;
  let hasAccount = !noAccount;
  if (hasAccount || potFunded || walletEthEmpty || walletOxtEmpty) {
    throw Error("Invalid state for quick setup");
  }
  console.log(`quick setup, noAccount=${noAccount}, potFunded=${potFunded}, walletEthEmpty=${walletEthEmpty}, walletOxtEmpty=${walletOxtEmpty}`)

  const {setRoute, setNavEnabled} = useContext(RouteContext);
  const [walletBalance, setWalletBalance] = useState<BigInt | null>(null);
  const [targetDeposit, setTargetDeposit] = useState<number | null>(null);

  // Create account state
  const [newSignerAddress, setNewSignerAddress] = useState<Address | null>(null);
  const [signerKeyError, setSignerKeyError] = useState(true);
  const [tx, setTx] = useState(new TransactionStatus());
  const txResult = React.createRef<TransactionProgress>();

  const [showEthAddressInstructions, setShowEthAddressInstructions] = React.useState(false);
  const [showSignerKeyInstructions, setShowSignerKeyInstructions] = React.useState(false);
  const [buttonCopiedState, setButtonCopiedState] = useState(false);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletSubscription = api.wallet_wait.subscribe(wallet => {
      console.log("add funds got wallet: ", wallet);
      setWalletBalance(wallet.oxtBalance);
    });

    // TODO: use live pricing: max(2 OXT, 2 USD)
    setTargetDeposit(2.0); // OXT

    return () => {
      walletSubscription.unsubscribe();
    };
  }, []);


  async function submitAddFunds() {
    let api = OrchidAPI.shared();
    let walletAddress = api.wallet.value ? api.wallet.value.address : null;

    if (walletAddress == null || newSignerAddress == null || targetDeposit == null || walletBalance == null) {
      return;
    }
    const addEscrow: BigInt = oxtToKeiki(targetDeposit);
    const addAmount = BigInt(walletBalance).minus(addEscrow); // why is wrapping needed?
    console.log("submit quick add funds: ", walletAddress, addAmount, addEscrow);
    if (addAmount < 0) {
      console.log("insufficient funds for tx.");
      return;
    }

    setTx(TransactionStatus.running());
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    try {
      let txId = await orchidAddFunds(walletAddress, newSignerAddress, addAmount, addEscrow);
      await api.updateSigners();
      setTx(TransactionStatus.result(txId, "Transaction Complete!"));
      api.updateWallet().then();
      api.updateTransactions().then();
    } catch (err) {
      setTx(TransactionStatus.error(`Transaction Failed: ${err}`));
    }
  }

  function copyEthAddress() {
    let api = OrchidAPI.shared();
    let walletAddress = api.wallet.value ? api.wallet.value.address : null;
    if (walletAddress == null) {
      return;
    }
    let text = walletAddress.toString();
    let dummy = document.createElement('input');
    document.body.appendChild(dummy);
    dummy.value = text;
    dummy.select();
    document.execCommand('copy');
    document.body.removeChild(dummy);

    // Show copied message in the button
    setButtonCopiedState(true);
    setTimeout(() => {
      setButtonCopiedState(false);
    }, 1000);
  }

  if (walletBalance == null || targetDeposit == null) {
    return <OverviewLoading/>
  }

  let api = OrchidAPI.shared();
  let walletAddress = api.wallet.value ? api.wallet.value.address.toString() : "...";

  // TODO: Incorporate live pricing
  let ticketFaceValue = 0.8; // TODO:
  const targetBalance = 2 * ticketFaceValue;
  let sufficientFundsAmount = targetDeposit + targetBalance;
  let sufficientFunds = keikiToOxt(walletBalance) >= sufficientFundsAmount;
  let insufficientFundsText =
    `You need a total of ${sufficientFundsAmount.toFixed(1)} OXT for a 
    starting balance of ${targetBalance} OXT and a ${targetDeposit} OXT deposit.`;

  let submitEnabled = sufficientFunds && !tx.isRunning() && !signerKeyError;
  let txCompletedSuccessfully = tx.state === TransactionState.Completed;

  return (
    <Container className="form-style">
      <label className="title">Quick Set Up</label>

      <p className="quick-setup-instructions">
        Copy the Ethereum Address to the Orchid App and paste your signer key from the Orchid App to
        create your account.
      </p>

      {/*Ethereum Address, todo: clean up this layout*/}
      <Row className="form-row" style={{
        display: "inline-flex",
        width: "100%",
        marginLeft: 0
      }}>
        <label>Ethereum Address</label>
        {/*info button*/}
        <span
          onClick={() => {
            setShowEthAddressInstructions(true);
          }}
          style={{paddingLeft: 8, paddingRight: 8}}>ⓘ</span>
        {/*address*/}
        <Col style={{
          flexGrow: 2,
          overflow: "hidden",
          textOverflow: "ellipsis",
          textAlign: "right",
          //color: buttonCopiedState ? "rebeccapurple" : "black"
        }}
             onClick={() => {
               copyEthAddress()
             }}>
          <span style={{fontSize: 14}}>{walletAddress}</span>
        </Col>
        {/*copy button*/}
        <Col style={{textAlign: "right", marginRight: 8, minWidth: buttonCopiedState ? 80 : 62}}
             onClick={() => {
               copyEthAddress()
             }}>
          <div>
            <span style={{fontSize: 20, color: "rebeccapurple"}}>⎘ </span>
            <span style={{
              fontSize: 15, color: "rebeccapurple"
            }}>{buttonCopiedState ? "Copied!" : "Copy"}</span>
          </div>
        </Col>
      </Row>

      <Row className="form-row">
        <Col style={{flexGrow: 2}}>
          <label style={{marginBottom: 0}}>From Available<span
            className={errorClass(!sufficientFunds)}>*</span></label>
        </Col>
        <Col>
          <div className="oxt-1-pad">
            {walletBalance == null ? "..." : keikiToOxtString(walletBalance, 2)}
          </div>
        </Col>
      </Row>
      <Row>
        <Col style={{marginTop: 16, marginBottom: 8, textAlign: "center", lineHeight: 1.2}}>
          <span className={errorClass(!sufficientFunds)}
                style={{marginLeft: 0, fontSize: 13}}>{insufficientFundsText}</span>
        </Col>
      </Row>

      <Row>
        <Col style={{marginLeft: 16, marginRight: 16, marginTop: 16}}><Divider/></Col>
      </Row>

      <Row className="form-row"
           style={{
             display: "inline-flex",
             alignItems: "baseline",
             marginTop: 16,
             marginLeft: 0
           }}
      >
        <label>Signer Key<span className={errorClass(signerKeyError)}> *</span></label>
        <span
          onClick={() => {
            setShowSignerKeyInstructions(true);
          }}
          style={{paddingLeft: 8, paddingRight: 16}}>ⓘ</span>
      </Row>
      <Row>
        <Col>
          <input
            className="address-input editable"
            type="text"
            placeholder="0x..."
            onChange={(e) => {
              const address = e.currentTarget.value;
              const valid = isEthAddress(address);
              setNewSignerAddress(valid ? address : null);
              setSignerKeyError(!valid);
            }}
          />
        </Col>
      </Row>

      <div className="Overview-bottomText">
      </div>
      <SubmitButton
        onClick={() => {
          setNavEnabled(true);
          submitAddFunds();
        }}
        hidden={potFunded || txCompletedSuccessfully}
        enabled={submitEnabled}>
        Transfer Available OXT
      </SubmitButton>

      <Visibility visible={!potFunded && !txCompletedSuccessfully}>
        <Row style={{
          paddingTop: 16,
          justifyContent: 'center',
        }} onClick={() => {
          setNavEnabled(true);
          setRoute(Route.CreateAccount)
        }}><span className={"link-button-style"}>Enter custom amount</span></Row>
      </Visibility>

      <TransactionProgress ref={txResult} tx={tx}/>

      <EthAddressInstructions
        show={showEthAddressInstructions}
        onHide={() => setShowEthAddressInstructions(false)}
      />
      <SignerKeyInstructions
        show={showSignerKeyInstructions}
        onHide={() => setShowSignerKeyInstructions(false)}
      />
    </Container>
  );
};

function EthAddressInstructions(props: any) {
  return (
    <Modal
      {...props}
      size="lg"
      aria-labelledby="contained-modal-title-vcenter"
      centered
    >
      <Modal.Header closeButton>
        <strong>What is the Ethereum Address?</strong>
      </Modal.Header>
      <Modal.Body>
        <p>
          Your <strong>Ethereum Address</strong> is the public address in your wallet that you use
          to receive funds.
        </p>
        <p>
          You will be prompted to enter it when you create a new hop in the Orchid App.
        </p>
      </Modal.Body>
    </Modal>
  );
}

function SignerKeyInstructions(props: any) {
  return (
    <Modal
      {...props}
      size="lg"
      aria-labelledby="contained-modal-title-vcenter"
      centered
    >
      <Modal.Header closeButton>
        <strong>What is the Signer Key?</strong>
      </Modal.Header>
      <Modal.Body>
        <p>The <strong>Signer Key</strong> allows you to link your Orchid Account to the Orchid App.
        </p>
        <p>You’ll be prompted to either choose an existing key or create a new one when you add a
          new hop.</p>
      </Modal.Body>
    </Modal>
  );
}

