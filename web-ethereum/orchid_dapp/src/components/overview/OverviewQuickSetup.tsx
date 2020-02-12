import React, {Dispatch, SetStateAction, useContext, useEffect, useState} from "react";
import {Col, Container, Modal, Row} from "react-bootstrap";
import {SubmitButton} from "../SubmitButton";
import {Route, RouteContext} from "../Route";
import {OverviewLoading, OverviewProps} from "./Overview";
import {
  GasPricingStrategy,
  keikiToOxt,
  keikiToOxtString,
  oxtToKeiki
} from "../../api/orchid-eth";
import {Divider, errorClass, Visibility} from "../../util/util";
import './Overview.css';
import {OrchidAPI} from "../../api/orchid-api";
import {TransactionProgress, TransactionState, TransactionStatus} from "../TransactionProgress";
import {OrchidContracts} from "../../api/orchid-eth-contracts";
import {S} from "../../i18n/S";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export interface OverviewQuickSetupProps {
  // The result of a completed transaction to display
  initialTxStatus: TransactionStatus | undefined,
  // Setter to return a completed quick setup transaction to the context
  txResultSetter: Dispatch<SetStateAction<TransactionStatus | undefined>>
}

export const OverviewQuickSetup: React.FC<OverviewProps & OverviewQuickSetupProps> = (props) => {

  // Preconditions
  let {noAccount, potFunded, walletEthEmpty, walletOxtEmpty, initialTxStatus} = props;
  // let hasAccount = !noAccount;
  // if (hasAccount || potFunded || walletEthEmpty || walletOxtEmpty) {
  //   throw Error("Invalid state for quick setup");
  // }
  console.log(`quick setup, noAccount=${noAccount}, potFunded=${potFunded}, walletEthEmpty=${walletEthEmpty}, walletOxtEmpty=${walletOxtEmpty}`)

  const {setRoute, setNavEnabled} = useContext(RouteContext);
  const [walletBalance, setWalletBalance] = useState<BigInt | null>(null);
  const [targetDeposit, setTargetDeposit] = useState<number | null>(null);

  // Create account state
  const [tx, setTx] = useState(initialTxStatus || new TransactionStatus());
  const txResult = React.createRef<TransactionProgress>();

  const [showEthAddressInstructions, setShowEthAddressInstructions] = React.useState(false);

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
    let wallet = api.wallet.value;
    if (wallet == null || targetDeposit == null || walletBalance == null) {
      return;
    }
    let walletAddress = wallet.address;
    const addEscrow: BigInt = oxtToKeiki(targetDeposit);
    const addAmount = BigInt(walletBalance).minus(addEscrow); // why is wrapping needed?
    console.log("submit quick add funds: ", walletAddress, addAmount, addEscrow);
    if (addAmount < 0) {
      console.log("insufficient funds for tx.");
      return;
    }

    setTx(TransactionStatus.running());
    console.log("tx is running");
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    // TODO: I believe this delay was to help allow the spinner to start. We should probably remove it.
    setTimeout(async () => {
      let _walletCapture = wallet;
      if (_walletCapture == null) {
        return;
      }
      try {
        // Create and save the new signer key
        console.log("create signer key");
        let newSigner = api.eth.orchidCreateSigner(_walletCapture);
        console.log("add funds");

        // Choose a gas price
        let medianGasPrice = await api.eth.medianGasPrice();
        let gasPrice = GasPricingStrategy.chooseGasPrice(
          OrchidContracts.add_funds_total_max_gas, medianGasPrice, _walletCapture.ethBalance);
        if (!gasPrice) {
          console.log("Add funds: gas price potentially too low.");
        }

        // Submit the tx
        let txId = await api.eth.orchidAddFunds(walletAddress, newSigner.address, addAmount, addEscrow, gasPrice);
        console.log("add funds complete");
        await api.updateSigners();
        let tx = TransactionStatus.result(txId, S.transactionComplete, newSigner);
        setTx(tx); // show the tx result
        props.txResultSetter(tx); // store the tx result in the context
        api.updateWallet().then();
        api.updateTransactions().then();
      } catch (err) {
        let tx = TransactionStatus.error(`${S.transactionFailed}: ${err}`);
        setTx(tx);
        props.txResultSetter(tx);
      }
    }, 300);
  }

  if (walletBalance == null || targetDeposit == null) {
    return <OverviewLoading/>
  }

  // TODO: Incorporate live pricing
  let ticketFaceValue = 0.8; // TODO:
  const targetBalance = 2 * ticketFaceValue;
  let sufficientFundsAmount = targetDeposit + targetBalance;
  let sufficientFunds = walletBalance >= oxtToKeiki(sufficientFundsAmount);
  let insufficientFundsText =
    `You need a total of ${sufficientFundsAmount.toFixedLocalized(1)} OXT for a starting balance of ${targetBalance} OXT and a ${targetDeposit} OXT deposit.`;

  let submitEnabled = sufficientFunds && !tx.isRunning();
  let txCompletedSuccessfully = tx.state === TransactionState.Completed;

  return (
    <Container className="form-style">
      <label className="title">{S.quickSetUp}</label>

      <p className="quick-setup-instructions">
        Create account with available Orchid tokens.
        {S.createAccountWithAvailable}
      </p>

      <Visibility visible={tx == null}>
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
      </Visibility>

      <Row>
        <Col style={{marginLeft: 16, marginRight: 16, marginTop: 16}}><Divider/></Col>
      </Row>

      <div className="Overview-bottomText">
      </div>
      <SubmitButton
        onClick={() => {
          setNavEnabled(true);
          submitAddFunds();
        }}
        hidden={potFunded || txCompletedSuccessfully}
        enabled={submitEnabled}>{S.transferAvailable} OXT: {walletBalance == null ? "0.00" : keikiToOxtString(walletBalance, 2)}
      </SubmitButton>

      <Visibility visible={!potFunded && !txCompletedSuccessfully}>
        <Row style={{
          paddingTop: 16,
          justifyContent: 'center',
        }} onClick={() => {
          setNavEnabled(true);
          setRoute(Route.CreateAccount)
        }}><span className={"link-button-style"}>{S.enterCustomAmount}</span></Row>
      </Visibility>

      <TransactionProgress ref={txResult} tx={tx}/>

      <EthAddressInstructions
        show={showEthAddressInstructions}
        onHide={() => setShowEthAddressInstructions(false)}
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

