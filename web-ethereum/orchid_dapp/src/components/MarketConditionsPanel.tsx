import React, {useContext, useEffect, useState} from "react";
import {Col, Collapse, Container, Row} from "react-bootstrap";
import {OrchidAPI} from "../api/orchid-api";
import {LotteryPot} from "../api/orchid-eth";
import {MarketConditions} from "../api/orchid-market-conditions";
import {WalletProviderContext} from "../index";
import {Cancellable, makeCancellable} from "../util/async-util";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const MarketConditionsPanel: React.FC = () => {

  const [shown, setShown] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [pot, setPot] = useState<LotteryPot | null>();
  const [marketConditions, setMarketConditions] = useState<MarketConditions>();
  let {fundsToken: funds} = useContext(WalletProviderContext);

  useEffect(() => {
    let cancellablePromises: Array<Cancellable> = [];
    let api = OrchidAPI.shared();
    let fetch = (async () => {
      if (!pot || !api.eth) {
        return;
      }
      try {
        let marketConditions = await makeCancellable(
          api.eth.marketConditions.for(pot), cancellablePromises).promise;
        setMarketConditions(marketConditions);
        setShown(marketConditions.ticketUnderwater);
      } catch (err) {
        // console.log("error getting market conditions: ", err);
      }
    });
    let potSubscription = api.lotteryPot.subscribe(async pot => {
      setPot(pot)
      fetch().then();
    });
    fetch().then();

    // todo: is this closing over stale state?  Switch to useInterval.
    let timer = setInterval(fetch, 15000/*ms*/);
    return () => {
      cancellablePromises.forEach(p => p.cancel());
      clearInterval(timer);
      potSubscription.unsubscribe();
    };
  }, [pot]);

  if (!pot || marketConditions === undefined || !(funds?.symbol)) {
    return <div/>
  }

  //let gasPrice = new ETH.fromNumberAsGwei(5.0);
  //let pricing = new Pricing(0.004, 5.0)
  //let pot = Mocks.lotteryPot(1.0, 20.0)

  let title = "Abnormal Market Conditions"
  let text = `Due to market conditions, which take into account network gas costs, ` +
    `and the price of ${funds?.symbol}, your account will not function. \n`

  let alertIcon =
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <mask id="mask0" mask-type="alpha" maskUnits="userSpaceOnUse" x="1" y="1" width="18"
            height="18">
        <path fillRule="evenodd" clipRule="evenodd"
              d="M10 1.66669C5.40002 1.66669 1.66669 5.40002 1.66669 10C1.66669 14.6 5.40002 18.3334 10 18.3334C14.6 18.3334 18.3334 14.6 18.3334 10C18.3334 5.40002 14.6 1.66669 10 1.66669ZM10 10.8334C9.54169 10.8334 9.16669 10.4584 9.16669 10V6.66669C9.16669 6.20835 9.54169 5.83335 10 5.83335C10.4584 5.83335 10.8334 6.20835 10.8334 6.66669V10C10.8334 10.4584 10.4584 10.8334 10 10.8334ZM9.16669 12.5V14.1667H10.8334V12.5H9.16669Z"
              fill="white"/>
      </mask>
      <g mask="url(#mask0)">
        <rect width="20" height="20" fill="white"/>
      </g>
    </svg>

  return (
    <Collapse in={shown} appear={true}>
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
          setExpanded(!expanded)
        }}>
          <Col style={{
            flexGrow: 0,
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            paddingRight: 0
          }}>
            <div style={{fontSize: '16px', width: '5px'}}>{expanded ? "▾" : "▸"}</div>
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
        <Collapse in={expanded}>
          <Row style={{marginTop: '12px', marginBottom: '8px'}}>
            <Col>
              {text}
            </Col>
          </Row>
        </Collapse>
      </Container>
    </Collapse>
  );
};


