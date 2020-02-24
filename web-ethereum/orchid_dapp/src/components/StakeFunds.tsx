import React, {FC, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {errorClass, parseFloatSafe} from "../util/util";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'
import {Address} from "../api/orchid-types";
import {GasPricingStrategy, isEthAddress, keikiToOxtString, oxtToKeiki} from "../api/orchid-eth";
import {OrchidContracts} from "../api/orchid-eth-contracts";
import {S} from "../i18n/S";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const StakeFunds: FC = () => {

  // Add funds state
  const [walletBalance, setWalletBalance] = useState<BigInt | null>(null);
  const [currentStakeAmount, setCurrentStakeAmount] = useState<BigInt | null>(null);

  const [addStakeAmount, setAddStakeAmount] = useState<number | null>(null);
  const [addStakeAmountError, setAddStakeAmountError] = useState(true);

  const [stakeeAddress, setStakeeAddress] = useState<Address | null>(null);
  const [stakeeAddressError, setStakeeAddressError] = useState(true);

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
    console.log("update current stake");
    let api = OrchidAPI.shared();
    if (stakeeAddress === null) {
      console.log("missing stakee address");
      return;
    }
    let stake = await api.eth.orchidGetStake(stakeeAddress);
    setCurrentStakeAmount(stake);
  }

  async function submitAddStake() {
    let api = OrchidAPI.shared();
    let wallet = api.wallet.value;
    if (!wallet) {
      return;
    }
    let walletAddress = wallet.address;
    console.log("submit add funds: ", walletAddress, addStakeAmount);
    if (walletAddress == null || addStakeAmount == null || stakeeAddress == null) {
      return;
    }

    try {
      const amountWei = oxtToKeiki(addStakeAmount);
      // TODO: reset the form

      // Choose a gas price
      let medianGasPrice = await api.eth.medianGasPrice();
      let gasPrice = GasPricingStrategy.chooseGasPrice(
        OrchidContracts.stake_funds_total_max_gas, medianGasPrice, wallet.ethBalance);
      if (!gasPrice) {
        console.log("Add funds: gas price potentially too low.");
      }

      let delayValue = BigInt(0);
      await api.eth.orchidStakeFunds(walletAddress, stakeeAddress, amountWei, delayValue, gasPrice);
      api.updateWallet().then();
      console.log("updating stake");
      updateCurrentStake().then();
    } catch (err) {
      console.log("error in staking: ", err);
    }
  }

  let submitEnabled = OrchidAPI.shared().wallet.value !== undefined && !addStakeAmountError;

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
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>{"Stakee (Provider) Address"}<span
            className={errorClass(stakeeAddressError)}> *</span></label>
        </Col>
        <Col>
          <input
            className="send-to-address editable"
            type="text"
            placeholder={S.address}
            onChange={(e) => {
              const address = e.currentTarget.value;
              const valid = isEthAddress(address);
              console.log("valid = ", valid, address);
              console.log("setStakeeAddress(", valid ? address : null);
              setStakeeAddress(valid ? address : null);
              console.log("stakee address set to: ", stakeeAddress);
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
            className="editable"
            onChange={(e) => {
              let amount = parseFloatSafe(e.currentTarget.value);
              setAddStakeAmount(amount);
              setAddStakeAmountError(amount == null || oxtToKeiki(amount) > (walletBalance || 0));
            }}
            type="number"
            placeholder={(0).toFixedLocalized(2)}
            defaultValue={undefined}
          />
        </Col>
      </Row>

      <SubmitButton onClick={() => submitAddStake()} enabled={submitEnabled}>
        {S.stakeOxt}
      </SubmitButton>
    </Container>
  );
};


