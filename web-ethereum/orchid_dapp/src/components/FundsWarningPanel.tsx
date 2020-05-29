import React, {useEffect, useState} from "react";
import {Col, Collapse, Container, Row} from "react-bootstrap";
import {OrchidPricingAPI, Pricing} from "../api/orchid-pricing";
import {ETH, GWEI, min, OXT} from "../api/orchid-types";
import {formatCurrency} from "../util/util";
import {OrchidAPI} from "../api/orchid-api";
import {LotteryPot} from "../api/orchid-eth";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const FundsWarningPanel: React.FC = () => {

  const [open, setOpen] = useState(false);
  const [pot, setPot] = useState<LotteryPot>();
  const [gasPrice, setGasPrice] = useState<GWEI>();
  const [pricing, setPricing] = useState<Pricing>();

  useEffect(() => {
    let api = OrchidAPI.shared();
    let potSubscription = api.lotteryPot_wait.subscribe(pot => {
      setPot(pot)
    });
    let fetch = (async () => {
      setPricing(await OrchidPricingAPI.shared().getPricing())
      setGasPrice(await api.eth.getGasPrice())
    });
    fetch().then();
    let timer = setInterval(fetch, 15000/*ms*/);

    return () => {
      clearInterval(timer);
      potSubscription.unsubscribe();
    };
  }, []);

  if (pot === undefined || gasPrice === undefined || pricing === undefined) {
    return <div/>
  }

  //let gasPrice = new GWEI(5.0);
  //let pricing = new Pricing(0.004, 5.0)
  //let pot = Mocks.lotteryPot(1.0, 20.0)

  // calculation
  let gasCostToRedeem: ETH = (gasPrice.multiply(OrchidPricingAPI.gasCostToRedeemTicket)).toEth();
  let oxtCostToRedeem: OXT = pricing.ethToOxt(gasCostToRedeem);
  let maxFaceValue: OXT = min(OXT.fromKeiki(pot.balance), OXT.fromKeiki(pot.escrow).divide(2.0));
  //let gasPriceHigh = gasPrice.value >= 15.0;
  let balanceLimited = BigInt(pot.balance).lesser(BigInt(pot.escrow).divide(2.0));

  // formatting
  //let ethPriceText = formatCurrency(1.0 / pricing.ethToUsdRate, "USD");
  //let oxtPriceText = formatCurrency(1.0 / pricing.oxtToUsdRate, "USD");
  //let gasPriceText = formatCurrency(gasPrice.value, "GWEI");
  //let maxFaceValueText = formatCurrency(maxFaceValue.value, "OXT");
  //let costToRedeemText = formatCurrency(oxtCostToRedeem.value, "OXT");
  let ticketUnderwater = oxtCostToRedeem.value >= maxFaceValue.value;

  if (!ticketUnderwater) {
    return <div/>
  }

  let limitedByTitleText: string = balanceLimited ? "Balance too low" : "Deposit size too small";
  let limitedByText: string = balanceLimited
    ? "Your max ticket value is currently limited by your balance of  " +
    `${formatCurrency(OXT.fromKeiki(pot.balance).value, 'OXT')}.  ` +
    "Consider adding OXT to your account balance."
    : "Your max ticket value is currently limited by your deposit of " +
    `${formatCurrency(OXT.fromKeiki(pot.escrow).value, 'OXT')}.  ` +
    "Consider adding OXT to your deposit or moving funds from your balance to your deposit.";

  let alertIcon =
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <mask id="mask0" mask-type="alpha" maskUnits="userSpaceOnUse" x="1" y="1" width="18"
            height="18">
        <path fill-rule="evenodd" clip-rule="evenodd"
              d="M10 1.66669C5.40002 1.66669 1.66669 5.40002 1.66669 10C1.66669 14.6 5.40002 18.3334 10 18.3334C14.6 18.3334 18.3334 14.6 18.3334 10C18.3334 5.40002 14.6 1.66669 10 1.66669ZM10 10.8334C9.54169 10.8334 9.16669 10.4584 9.16669 10V6.66669C9.16669 6.20835 9.54169 5.83335 10 5.83335C10.4584 5.83335 10.8334 6.20835 10.8334 6.66669V10C10.8334 10.4584 10.4584 10.8334 10 10.8334ZM9.16669 12.5V14.1667H10.8334V12.5H9.16669Z"
              fill="white"/>
      </mask>
      <g mask="url(#mask0)">
        <rect width="20" height="20" fill="white"/>
      </g>
    </svg>

  return (
    <Container
      style={{
        color: "white",
        backgroundColor: "#BE092A",
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
          <span>{alertIcon} {limitedByTitleText}</span>
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
            {limitedByText}
          </Col>
        </Row>
      </Collapse>
    </Container>
  );
};


