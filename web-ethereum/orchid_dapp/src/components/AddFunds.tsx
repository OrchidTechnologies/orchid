import React, {FC, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {
  Divider,
  errorClass,
  getBoolParam,
  parseFloatSafe,
  useInterval,
  Visibility
} from "../util/util";
import {TransactionStatus, TransactionProgress} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'
import {Address, GWEI, OXT} from "../api/orchid-types";
import {
  GasPricingStrategy,
  isEthAddress,
  keikiToOxtString,
  LotteryPot,
  oxtToKeiki
} from "../api/orchid-eth";
import {OrchidContracts} from "../api/orchid-eth-contracts";
import {S} from "../i18n/S";
import {Orchid} from "../api/orchid";
import ProgressLine from "./ProgressLine";
import {MarketConditions} from "./MarketConditionsPanel";
import {OrchidPricingAPI} from "../api/orchid-pricing";

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
  const [addEscrow, setAddEscrow] = useState<number | null>(null);
  const [amountError, setAmountError] = useState(false);
  const [escrowError, setEscrowError] = useState(false);
  const [tx, setTx] = useState(new TransactionStatus());
  const txResult = React.createRef<TransactionProgress>();
  const [walletBalance, setWalletBalance] = useState<BigInt | null>(null);
  const [pot, setPot] = useState<LotteryPot | null>(null);
  const [marketConditions, setMarketConditions] = useState<MarketConditions>();

  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletSubscription = api.wallet_wait.subscribe(wallet => {
      console.log("add funds got wallet: ", wallet);
      setWalletBalance(wallet.oxtBalance);
    });
    let potSubscription = api.lotteryPot_wait.subscribe(async pot => {
      setPot(pot)
    });

    // prime data sources
    OrchidPricingAPI.shared().getPricing();
    api.eth.getGasPrice();

    return () => {
      potSubscription.unsubscribe();
      walletSubscription.unsubscribe();
    };
  }, []);

  useInterval(()=>{
    fetchMarketConditions().then();
  }, 15000) ;

  useEffect(() => {
    fetchMarketConditions().then();
  }, [pot, addAmount, addEscrow]);

  async function fetchMarketConditions() {
    console.log("fetch market conditions");
    if (pot == null || addAmount == null || addEscrow == null) {
      console.log("null market conditions: ", pot, addAmount, addEscrow);
      setMarketConditions(undefined);
      return;
    }
    console.log("getting market conditions");
    setMarketConditions(
      await MarketConditions.forBalance(
        OXT.fromKeiki(pot.balance).add(new OXT(addAmount)),
        OXT.fromKeiki(pot.escrow).add(new OXT(addEscrow)))
    );
    console.log("got market conditions: ");
  }

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
    if (walletAddress == null || signerAddress == null || walletBalance == null) {
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
      const amountKeiki = oxtToKeiki(addAmount || 0);
      const escrowKeiki = oxtToKeiki(addEscrow || 0 );

      // Choose a gas price
      let medianGasPrice: GWEI = await api.eth.getGasPrice();
      let gasPrice = GasPricingStrategy.chooseGasPrice(
        OrchidContracts.add_funds_total_max_gas, medianGasPrice, wallet.ethBalance);
      if (!gasPrice) {
        console.log("Add funds: gas price potentially too low.");
      }

      let txId = await api.eth.orchidAddFunds(
        walletAddress, signerAddress, amountKeiki, escrowKeiki, walletBalance, gasPrice);
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
    && !escrowError
    && (addAmount != null || addEscrow != null);

  let addBalanceStr: string | undefined;
  let addDepositStr: string | undefined;
  if (pot != null) {
    let addBalance = Orchid.recommendedBalance.subtract(OXT.fromKeiki(pot.balance));
    let addDeposit = Orchid.recommendedDeposit.subtract(OXT.fromKeiki(pot.escrow));
    if (addBalance.value > 0) {
      addBalanceStr = addBalance.value.toFixedLocalized(2);
    }
    if (addDeposit.value > 0) {
      addDepositStr = addDeposit.value.toFixedLocalized(2);
    }
  }

  let efficiencyPerc: string = "";
  let efficiencyColor: string = "";
  if (marketConditions) {
    let efficiency = marketConditions.efficiency;
    efficiencyPerc = (efficiency * 100).toFixed()+"%";
    if (efficiency <= 0.2) { efficiencyColor = "red" }
    if (efficiency > 0.2 && efficiency <= 0.6) { efficiencyColor = "yellow" }
    if (efficiency > 0.6) { efficiencyColor = "green" }
  }
  let showMarketConditions = getBoolParam("market_meter", false);

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
            placeholder={addBalanceStr || (0).toFixedLocalized(2)}
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
            placeholder={addDepositStr || (0).toFixedLocalized(2)}
            defaultValue={props.defaultAddEscrow}
          />
        </Col>
      </Row>

      {/*Market conditions meter*/}
      <Visibility visible={marketConditions !== undefined && showMarketConditions}>
        <Row className="form-row">
          <Col>
            <label>Market efficiency</label>
          </Col>
          <Col>
            <ProgressLine label="" visualParts={[ { percentage: efficiencyPerc, color: efficiencyColor } ]} />
          </Col>
          <Col style={{flexGrow: 0}}>
            {efficiencyPerc}
          </Col>
        </Row>
      </Visibility>

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
      <p/><em>Version 0.9.17</em>
    </Container>
  );
};


