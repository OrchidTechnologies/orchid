import React, {FC, useEffect, useRef, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {errorClass, parseFloatSafe, parseIntSafe} from "../util/util";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds2.css'
import {EthAddress} from "../api/orchid-types";
import {GasPricingStrategy, isEthAddress, keikiToOxtString, oxtToKeiki} from "../api/orchid-eth";
import {OrchidContracts} from "../api/orchid-eth-contracts";
import {S} from "../i18n/S";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const StakeFunds: FC = () => {
  const defaultStakeDelay = 90 * 24 * 3600; // 90 days in seconds

  // Add funds state
  const [walletBalance, setWalletBalance] = useState<BigInt | null>(null);
  const [currentStakeAmount, setCurrentStakeAmount] = useState<BigInt | null>(null);

  const [addStakeAmount, setAddStakeAmount] = useState<number | null>(null);
  const [addStakeAmountError, setAddStakeAmountError] = useState(true);

  const [stakeeAddress, setStakeeAddress] = useState<EthAddress | null>(null);
  const [stakeeAddressError, setStakeeAddressError] = useState(true);

  const [stakeDelaySeconds, setStakeDelaySeconds] = useState<number | null>(defaultStakeDelay);
  const [stakeDelayError, setStakeDelayError] = useState(false);

  const [txRunning, setTxRunning] = useState(false);
  let amountInput = useRef<HTMLInputElement | null>(null);

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

  useEffect(() => {
    updateCurrentStake().then();
  }, [stakeeAddress]);

  async function updateCurrentStake() {
    let api = OrchidAPI.shared();
    if (stakeeAddress === null) {
      //console.log("missing stakee address");
      return;
    }
    let stake = await api.eth.orchidGetStake(stakeeAddress);
    setCurrentStakeAmount(stake);
  }

  function clearForm() {
    let field = amountInput.current;
    if (field != null) {
      field.value = "";
    }
  }

  async function submitAddStake() {
    let api = OrchidAPI.shared();
    let wallet = api.wallet.value;
    if (!wallet) {
      return;
    }
    let walletAddress = wallet.address;
    let walletBalance = wallet.oxtBalance;
    console.log("submit add funds: ", walletAddress, addStakeAmount, stakeDelaySeconds);
    if (walletAddress == null || addStakeAmount == null || stakeeAddress == null
      || stakeDelaySeconds == null || walletBalance == null) {
      return;
    }

    try {
      setTxRunning(true);
      const amountWei = oxtToKeiki(addStakeAmount);

      // Choose a gas price
      let medianGasPrice = await api.eth.getGasPrice();
      let gasPrice = GasPricingStrategy.chooseGasPrice(
        OrchidContracts.stake_funds_total_max_gas, medianGasPrice, wallet.ethBalance);
      if (!gasPrice) {
        console.log("Add funds: gas price potentially too low.");
      }

      let delayValue = BigInt(stakeDelaySeconds); // seconds
      await api.eth.orchidStakeFunds(
        walletAddress, stakeeAddress, amountWei, walletBalance, delayValue, gasPrice);
      api.updateWallet().then();
      console.log("updating stake");
      updateCurrentStake().then();
      clearForm();
    } catch (err) {
      console.log("error in staking: ", err);
    } finally {
      setTxRunning(false);
    }
  }

  let submitEnabled =
    OrchidAPI.shared().wallet.value !== undefined
    && !addStakeAmountError
    && !stakeeAddressError
    && !txRunning;
  let stakeDelayDaysStr =
    stakeDelaySeconds != null ? ((stakeDelaySeconds / (24 * 3600)).toLocaleString() + " " + S.days) : "";
  return (
    <Container className="form-style">
      <label className="title">{S.stakeFunds}</label>

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

      {/*Current Stake*/}
      <Row className="form-row">
        <Col>
          <label>{S.currentStake}</label>
        </Col>
        <Col>
          <div className="oxt-1-pad">
            {currentStakeAmount == null ? "..." : keikiToOxtString(currentStakeAmount, 2)}
          </div>
        </Col>
      </Row>

      {/*Stakee Address*/}
      <Row
        className="form-row" noGutters={true}>
        <Col style={{whiteSpace: 'nowrap'}}>
          <label>{S.stakeeProvider}<span
            className={errorClass(stakeeAddressError)}> *</span></label>
        </Col>
        <Col>
          <input
            spellCheck={false}
            className="editable"
            type="text"
            placeholder={S.address+'    '}
            onChange={(e) => {
              const address = e.currentTarget.value;
              const valid = isEthAddress(address);
              setStakeeAddress(valid ? address : null);
              setStakeeAddressError(!valid);
            }}
          />
        </Col>
      </Row>

      {/*Add to Stake */}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>{S.addToStake}<span
            className={errorClass(addStakeAmountError)}> *</span></label>
        </Col>
        <Col>
          <input
            ref={amountInput}
            className="editable"
            onChange={(e) => {
              let amount = parseFloatSafe(e.currentTarget.value);
              setAddStakeAmount(amount);
              setAddStakeAmountError(amount == null || oxtToKeiki(amount) > (walletBalance || 0));
            }}
            type="number"
            placeholder={S.oxt}
            defaultValue={undefined}
          />
        </Col>
      </Row>

      {/*Stake Delay*/}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>{S.delaySeconds}<span className={errorClass(stakeDelayError)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onChange={(e) => {
              let delay = parseIntSafe(e.currentTarget.value);
              setStakeDelaySeconds(delay);
              setStakeDelayError(delay == null || delay < 0);
            }}
            type="number"
            placeholder={(0).toString()}
            defaultValue={defaultStakeDelay}
          />
          <label style={{textAlign: "center"}}>{stakeDelayDaysStr}</label>
        </Col>
      </Row>

      <SubmitButton onClick={() => submitAddStake()} enabled={submitEnabled}>
        {S.stakeOxt}
      </SubmitButton>
    </Container>
  );
};


