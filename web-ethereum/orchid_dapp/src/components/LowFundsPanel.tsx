import React, {useEffect, useState} from "react";
import {Col, Collapse, Container, Row} from "react-bootstrap";
import {OXT} from "../api/orchid-types";
import {OrchidAPI} from "../api/orchid-api";
import {LotteryPot} from "../api/orchid-eth";
import {CancellablePromise, formatCurrency, makeCancelable} from "../util/util";
import {Orchid} from "../api/orchid";
import {AccountRecommendation} from "./MarketConditionsPanel";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const LowFundsPanel: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [pot, setPot] = useState<LotteryPot|null>();
  const [accountRecommendation, setAccountRecommendation] = useState<AccountRecommendation | null>(null);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let potSubscription = api.lotteryPot.subscribe(pot => {
      setPot(pot)
    });

    let getRecommendation: CancellablePromise<AccountRecommendation> =
      makeCancelable(Orchid.minViableAccountComposition());
    (async () => {
      try {
        setAccountRecommendation(await getRecommendation.promise);
      } catch (err) {
        if (err.isCanceled) {
          //console.log("recommendation cancelled")
        } else {
          //console.log("unable to fetch min viable account info", err)
        }
      }
    })();

    return () => {
      getRecommendation.cancel()
      potSubscription.unsubscribe();
    };
  }, []);

  if (!pot || accountRecommendation == null) {
    return <div/>
  }

  //let pot = Mocks.lotteryPot(1.0, 20.0)

  let balanceLow = OXT.fromKeiki(pot.balance).lt(accountRecommendation.balance);
  let depositLow = OXT.fromKeiki(pot.escrow).lt(accountRecommendation.deposit);

  if (!balanceLow && !depositLow) {
    return <div/>
  }

  let balance = OXT.fromKeiki(pot.balance);
  let balanceStr = formatCurrency(balance.floatValue, 'OXT');
  let deposit = OXT.fromKeiki(pot.escrow);
  let depositStr = formatCurrency(deposit.floatValue, 'OXT');
  let addBalanceStr = accountRecommendation.balance.subtract(balance).floatValue.toFixedLocalized(2) + ' OXT';
  let addDepositStr = accountRecommendation.deposit.subtract(deposit).floatValue.toFixedLocalized(2) + ' OXT';

  let title;
  let text;

  if (balanceLow) {
    title = "Balance too low";
    text = `Your balance of ${balanceStr} is too low. Add at least ${addBalanceStr} to your balance for the Orchid app to function.`;
  }
  if (depositLow) {
    title = "Deposit too low";
    text = `Your deposit of ${depositStr} is too low. Add at least ${addDepositStr} to your deposit for the Orchid app to function.`;
  }
  if (depositLow && balanceLow) {
    title = "Balance & deposit too low";
    text = `Your deposit and balance are too low.  ` +
      `Add at least ${addDepositStr} to your deposit and ${addBalanceStr} to your balance for the Orchid app to function.`;
  }

  let alertIcon =
    <svg width="21" height="21" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <mask id="mask0" mask-type="alpha" maskUnits="userSpaceOnUse" x="1" y="1" width="18"
            height="18">
        <path fillRule="evenodd" clipRule="evenodd"
              d="M10 1.66669C5.40002 1.66669 1.66669 5.40002 1.66669 10C1.66669 14.6 5.40002 18.3334 10 18.3334C14.6 18.3334 18.3334 14.6 18.3334 10C18.3334 5.40002 14.6 1.66669 10 1.66669ZM10 10.8334C9.54169 10.8334 9.16669 10.4584 9.16669 10V6.66669C9.16669 6.20835 9.54169 5.83335 10 5.83335C10.4584 5.83335 10.8334 6.20835 10.8334 6.66669V10C10.8334 10.4584 10.4584 10.8334 10 10.8334ZM9.16669 12.5V14.1667H10.8334V12.5H9.16669Z"
              fill="white"/>
      </mask>
      <g mask="url(#mask0)">
        <rect width="20" height="20" fill="#C30938"/>
      </g>
    </svg>;

  return (
    <Container
      style={{
        color: "black",
        backgroundColor: "#EBEDF6",
        width: "100%",
        padding: "12px",
        paddingLeft: '24px',
        paddingRight: '24px',
      }}
    >
      <Row onClick={() => {
        setOpen(!open)
      }}>
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
          <span>{alertIcon}</span><span style={{paddingLeft: '20px'}}>{title}</span>
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
        </Col>
      </Row>
      <Collapse in={open}>
        <Row style={{marginTop: '12px', marginBottom: '8px'}}>
          <Col>
            {text}
          </Col>
        </Row>
      </Collapse>
    </Container>
  );
};


