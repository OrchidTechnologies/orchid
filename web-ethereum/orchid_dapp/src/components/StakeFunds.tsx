import React, {FC, useCallback, useContext, useEffect, useRef, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {errorClass, parseFloatSafe, parseIntSafe} from "../util/util";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Row} from "react-bootstrap";
import './AddFunds.css'
import {isEthAddress } from "../api/orchid-eth";
import {S} from "../i18n/S";
import {EthAddress} from "../api/orchid-eth-types";
import {LotFunds} from "../api/orchid-eth-token-types";
import {WalletProviderContext} from "../index";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const StakeFunds: FC = () => {
  const defaultStakeDelay = 90 * 24 * 3600; // 90 days in seconds

  // Add funds state
  const [walletBalance, setWalletBalance] = useState<LotFunds | null>(null);
  const [currentStakeAmount, setCurrentStakeAmount] = useState<LotFunds | null>(null);

  const [addStakeAmount, setAddStakeAmount] = useState<number | null>(null);
  const [addStakeAmountError, setAddStakeAmountError] = useState(true);

  const [stakeeAddress, setStakeeAddress] = useState<EthAddress | null>(null);
  const [stakeeAddressError, setStakeeAddressError] = useState(true);

  const [stakeDelaySeconds, setStakeDelaySeconds] = useState<number | null>(defaultStakeDelay);
  const [stakeDelayError, setStakeDelayError] = useState(false);

  const [txRunning, setTxRunning] = useState(false);
  let amountInput = useRef<HTMLInputElement | null>(null);

  let {fundsToken: fundsTokenType} = useContext(WalletProviderContext);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletSubscription = api.wallet.subscribe(wallet => {
      //console.log("add funds got wallet: ", wallet);
      setWalletBalance(wallet?.fundsBalance ?? null);
    });
    return () => {
      walletSubscription.unsubscribe();
    };
  }, []);

  const updateCurrentStake = useCallback(async () => {
    let api = OrchidAPI.shared();
    if (!api.eth) { return }
    if (stakeeAddress === null) {
      //console.log("missing stakee address");
      return;
    }
    let stake: LotFunds = await api.eth.orchidGetStake(stakeeAddress);
    setCurrentStakeAmount(stake);
  }, [stakeeAddress]);

  useEffect(() => {
    updateCurrentStake().then();
  }, [updateCurrentStake, stakeeAddress]);

  function clearForm() {
    let field = amountInput.current;
    if (field != null) {
      field.value = "";
    }
  }

  async function submitAddStake() {
    let api = OrchidAPI.shared();
    if (!fundsTokenType) { return }
    let wallet = api.wallet.value;
    if (!wallet || !api.eth) {
      return;
    }
    let walletAddress = wallet.address;
    console.log("submit add funds: ", walletAddress, addStakeAmount, stakeDelaySeconds);
    if (walletAddress == null || addStakeAmount == null || stakeeAddress == null
      || stakeDelaySeconds == null) {
      return;
    }

    try {
      setTxRunning(true);
      const addAmountFunds: LotFunds = fundsTokenType.fromNumber(addStakeAmount);

      let delayValue: BigInt = BigInt(stakeDelaySeconds); // seconds
      await api.eth.orchidStakeFunds(
        walletAddress, stakeeAddress, addAmountFunds, wallet, delayValue);
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
          <div className="funds-1-pad">
            {walletBalance == null ? "..." : walletBalance.toFixedLocalized(2)}
          </div>
        </Col>
      </Row>

      {/*Current Stake*/}
      <Row className="form-row">
        <Col>
          <label>{S.currentStake}</label>
        </Col>
        <Col>
          <div className="funds-1-pad">
            {currentStakeAmount == null ? "..." : currentStakeAmount.toFixedLocalized(2)}
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
              if (fundsTokenType) {
                setAddStakeAmountError(amount == null || fundsTokenType.fromNumber(amount).gt(walletBalance || fundsTokenType.zero));
              }
            }}
            type="number"
            placeholder={fundsTokenType?.symbol ?? "Funds"}
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
        {S.stake}
      </SubmitButton>
    </Container>
  );
};


