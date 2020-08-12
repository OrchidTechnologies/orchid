import React, {useEffect, useState} from "react";
import {Col, Collapse, Container, Row} from "react-bootstrap";
import {OrchidPricingAPI, Pricing} from "../api/orchid-pricing";
import {ETH, GWEI, KEIKI, min, OXT, USD} from "../api/orchid-types";
import {OrchidAPI} from "../api/orchid-api";
import {LotteryPot, OrchidEthereumAPI} from "../api/orchid-eth";
import {OrchidContracts} from "../api/orchid-eth-contracts";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

/// A recommendation for account composition based on current market rates.
export class AccountRecommendation {
  public balance: OXT;
  public deposit: OXT;
  public txEth: ETH; // ETH required for the transaction
  public txUsd: ETH; // USD equivalent of the ETH required for the transaction

  constructor(balance: OXT, deposit: OXT, txEth: ETH, txUsd: USD) {
    this.balance = balance;
    this.deposit = deposit;
    this.txEth = txEth;
    this.txUsd = txUsd;
  }
}

export class MarketConditions {
  public gasCostToRedeem: ETH
  public oxtCostToRedeem: OXT
  public maxFaceValue: OXT
  public ticketUnderwater: boolean
  public efficiency: number

  constructor(gasCostToRedeem: ETH, oxtCostToRedeem: OXT, maxFaceValue: OXT, ticketUnderwater: boolean, efficiency: number) {
    this.gasCostToRedeem = gasCostToRedeem;
    this.oxtCostToRedeem = oxtCostToRedeem;
    this.maxFaceValue = maxFaceValue;
    this.ticketUnderwater = ticketUnderwater;
    this.efficiency = efficiency;
  }

  static async for(pot: LotteryPot): Promise<MarketConditions> {
    return this.forBalance(OXT.fromKeiki(pot.balance), OXT.fromKeiki(pot.escrow));
  }

  /// Given a target efficiency and a desired number of face value multiples in the balance
  /// (assuming two in the deposit) recommend balance, deposit, and required ETH amounts based
  // on current market conditions.
  static async recommendation(targetEfficiency: number, balanceFaceValues: number): Promise<AccountRecommendation> {
    if (targetEfficiency >= 1.0) {
      throw Error("Invalid efficiency target: cannot equal or exceed 1.0");
    }
    targetEfficiency = Math.min(targetEfficiency, 0.99);
    let {oxtCostToRedeem} = await this.getCostToRedeemTicket();
    let faceValue: OXT = oxtCostToRedeem.divide(1.0 - targetEfficiency);
    let deposit = faceValue.multiply(2.0);
    let balance = faceValue.multiply(balanceFaceValues);

    // Recommend the amount of ETH required for the account creation
    let api = OrchidAPI.shared();
    let gasPrice: GWEI = await api.eth.getGasPrice();
    let txEthRequired: ETH = gasPrice.multiply(OrchidContracts.add_funds_total_max_gas).toEth();
    let pricing: Pricing = await OrchidPricingAPI.shared().getPricing();
    let txUsdEthEqvuivalent = pricing.ethToUSD(txEthRequired);

    return new AccountRecommendation(balance, deposit, txEthRequired, txUsdEthEqvuivalent);
  }

  static async forBalance(balance: OXT, escrow: OXT): Promise<MarketConditions> {
    console.log("fetch market conditions")
    let {gasCostToRedeem, oxtCostToRedeem} = await this.getCostToRedeemTicket();
    let maxFaceValue: OXT = min(balance, escrow.divide(2.0));
    let ticketUnderwater = oxtCostToRedeem.value >= maxFaceValue.value;

    // value received as a fraction of ticket face value
    let efficiency = Math.max(0, maxFaceValue.subtract(oxtCostToRedeem).value / maxFaceValue.value);

    return new MarketConditions(gasCostToRedeem, oxtCostToRedeem, maxFaceValue, ticketUnderwater, efficiency);
  }

  private static async getCostToRedeemTicket() {
    let api = OrchidAPI.shared();
    let pricing: Pricing = await OrchidPricingAPI.shared().getPricing();
    let gasPrice: GWEI = await api.eth.getGasPrice();
    let gasCostToRedeem: ETH = (gasPrice.multiply(OrchidPricingAPI.gasCostToRedeemTicket)).toEth();
    let oxtCostToRedeem: OXT = pricing.ethToOxt(gasCostToRedeem);
    return {gasCostToRedeem, oxtCostToRedeem};
  }
}

export const MarketConditionsPanel: React.FC = () => {

  const [open, setOpen] = useState(false);
  const [pot, setPot] = useState<LotteryPot>();
  const [marketConditions, setMarketConditions] = useState<MarketConditions>();

  useEffect(() => {
    let api = OrchidAPI.shared();
    let fetch = (async () => {
      if (!pot) {
        return;
      }
      setMarketConditions(await MarketConditions.for(pot));
    });
    let potSubscription = api.lotteryPot_wait.subscribe(async pot => {
      setPot(pot)
      fetch().then();
    });
    fetch().then();

    // todo: is this closing over stale state?  Switch to useInterval.
    let timer = setInterval(fetch, 15000/*ms*/);
    return () => {
      clearInterval(timer);
      potSubscription.unsubscribe();
    };
  }, []);

  if (pot === undefined || marketConditions === undefined) {
    return <div/>
  }

  //let gasPrice = new GWEI(5.0);
  //let pricing = new Pricing(0.004, 5.0)
  //let pot = Mocks.lotteryPot(1.0, 20.0)

  // calculation

  if (!marketConditions.ticketUnderwater) {
    return <div/>
  }

  let title = "Abnormal Market Conditions"
  let text = "Due to market conditions, which take into account Ethereum gas costs, the price of OXT and the price of OXT/ETH, your account will not function. \n"

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


