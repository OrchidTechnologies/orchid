import React, {Component, useContext} from 'react';
import {OrchidAPI} from "../api/orchid-api";
import {LockStatus} from "./LockStatus";
import {errorClass, Visibility} from "../util/util";
import './Info.css'
import {Button, Col, Container, Row} from "react-bootstrap";
import {Subscription} from "rxjs";
import {AccountQRCode} from "./AccountQRCode";
import {S} from "../i18n/S";
import {EfficiencyMeterRow} from "./EfficiencyMeter";
import {Spacer} from "./Spacer";
import {AccountRecommendation} from "../api/orchid-market-conditions";
import {WalletProviderContext} from "../index";
import {WalletProviderStatus} from "../api/orchid-eth-web3";
import {CancellablePromise, makeCancellable} from "../util/async-util";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export function Info() {
  let walletContext: WalletProviderStatus = useContext(WalletProviderContext);
  return <InfoImpl walletContext={walletContext}/>
}

export class InfoImpl extends Component<{
  walletContext: WalletProviderStatus
}, any> {
  state = {
    signerAddress: "",
    signerConfigString: null,
    walletAddress: "",
    gasBalance: "",
    gasBalanceError: true,
    lotBalance: "",
    lotBalanceError: true,
    potBalance: "",
    potEscrow: "",
    accountRecommendationBalanceMin: null,
    accountRecommendationBalance: null,
    accountRecommendationDepositMin: null,
    accountRecommendationDeposit: null,
    marketConditions: null
  };
  subscriptions: Subscription [] = [];
  cancellablePromises: Array<CancellablePromise<AccountRecommendation>> = [];
  walletAddressInput = React.createRef<HTMLInputElement>();
  signerAddressInput = React.createRef<HTMLInputElement>();

  componentDidMount(): void {
    let api = OrchidAPI.shared();

    this.subscriptions.push(
      api.signer.subscribe(signer => {
        this.setState({
          signerAddress: signer != null ? signer.address : "",
          signerConfigString: signer != null ? signer.toConfigString() : null
        });
      }));

    this.subscriptions.push(
      api.wallet.subscribe(wallet => {
        this.setState({
          walletAddress: wallet?.address ?? "",
          gasBalance: wallet?.gasFundsBalance.toFixedLocalized(4) ?? "",
          gasBalanceError: wallet?.gasFundsBalance.lteZero() ?? false,
          lotBalance: wallet?.fundsBalance.toFixedLocalized(4) ?? "",
          lotBalanceError: wallet?.fundsBalance.lteZero() ?? false,
        });
      }));

    this.subscriptions.push(
      api.lotteryPot.subscribe(pot => {
        if (!pot) {
          this.setState({
            potBalance: "",
            potEscrow: "",
            marketConditions: null
          });
        } else {
          this.setState({
            potBalance: pot.balance.toFixedLocalized(4),
            potEscrow: pot.escrow.toFixedLocalized(4),
          });
          try {
            if (api.eth) {
              api.eth.marketConditions.for(pot).then(marketConditions => {
                this.setState({marketConditions: marketConditions});
              });
            } else {
              this.setState({marketConditions: null});
            }
          } catch (err) {
            console.log(err)
          }
        }
      }));

    (async () => {
      if (!api.eth) {
        return
      }
      try {
        let minViableAccountRecommendation =
          await makeCancellable(api.eth.marketConditions.minViableAccountComposition(), this.cancellablePromises).promise;
        let accountRecommendation =
          await makeCancellable(api.eth.marketConditions.recommendedAccountComposition(), this.cancellablePromises).promise;
        this.setState({
          accountRecommendationBalanceMin: minViableAccountRecommendation.balance.toFixedLocalized(),
          accountRecommendationDepositMin: minViableAccountRecommendation.deposit.toFixedLocalized(),
          accountRecommendationBalance: accountRecommendation.balance.toFixedLocalized(),
          accountRecommendationDeposit: accountRecommendation.deposit.toFixedLocalized()
        });
      } catch (err) {
        console.log("unable to fetch min viable account info: ", err)
      }
    })();
  }

  componentWillUnmount(): void {
    this.cancellablePromises.forEach(p => p.cancel());
    this.subscriptions.forEach(sub => {
      sub.unsubscribe()
    })
  }

  copyWalletAddress() {
    if (this.walletAddressInput.current == null) {
      return;
    }
    this.walletAddressInput.current.select();
    document.execCommand('copy');
  };

  copySignerAddress() {
    if (this.signerAddressInput.current == null) {
      return;
    }
    this.signerAddressInput.current.select();
    document.execCommand('copy');
  };

  render() {
    const {fundsToken: funds, gasToken: gas} = this.props.walletContext;

    return (
      <Container className="Balances form-style">
        <label className="title">{S.info}</label>

        {/*wallet address*/}
        <label style={{fontWeight: "bold"}}>{S.funderWalletAddress}</label>
        <Row noGutters={true}>
          <Col style={{flexGrow: 10}}>
            <input type="text"
                   style={{textOverflow: "ellipsis"}}
                   ref={this.walletAddressInput}
                   value={this.state.walletAddress} placeholder={S.address} readOnly/>
          </Col>
          <Col style={{marginLeft: '8px'}}>
            <Button variant="light" onClick={this.copyWalletAddress.bind(this)}>{S.copy}</Button>
          </Col>
        </Row>

        {/*wallet balance*/}
        <Row>
          <Col>
            <label className="form-row-label">{gas?.symbol ?? "Gas Funds"}
              <span className={errorClass(this.state.gasBalanceError)}> * </span>
            </label>
            <input className="form-row-field" type="text"
                   value={this.state.gasBalance}
                   readOnly/>
          </Col>
          <Col>
            <label className="form-row-label">{funds?.symbol ?? "Funds"}
              <span className={errorClass(this.state.lotBalanceError)}> * </span>
            </label>
            <input className="form-row-field" type="text"
                   value={this.state.lotBalance}
                   readOnly/>
          </Col>
        </Row>

        {/*signer address*/}
        <label style={{fontWeight: "bold", marginTop: "16px"}}>{S.signerAddress}</label>
        <Row noGutters={true}>
          <Col style={{flexGrow: 10}}>
            <input type="text"
                   style={{textOverflow: "ellipsis"}}
                   ref={this.signerAddressInput}
                   value={this.state.signerAddress} placeholder={S.address} readOnly/>
          </Col>
          <Col style={{marginLeft: '8px'}}>
            <Button variant="light" onClick={this.copySignerAddress.bind(this)}>{S.copy}</Button>
          </Col>
        </Row>

        {/*account QR Code*/}
        <Visibility visible={this.state.signerConfigString !== null}>
          <AccountQRCode data={this.state.signerConfigString}/>
        </Visibility>

        {/*pot balance and deposit*/}
        <label style={{fontWeight: "bold", marginTop: "16px"}}>{S.orchidAccount}</label>
        <Row>
          <Col>
            <label className="form-row-label">{S.balance}</label>
            <input className="form-row-field"
                   value={this.state.potBalance}
                   type="text" readOnly/>
          </Col>
          <Col>
            <label className="form-row-label">{S.deposit}</label>
            <input className="form-row-field"
                   value={this.state.potEscrow}
                   type="text" readOnly/>
          </Col>
        </Row>

        {/*recommended account balance and deposit*/}
        <label style={{fontWeight: "bold", marginTop: "16px"}}>Recommended Account</label>
        <Row>
          <Col>
            <label className="form-row-label">{S.balance}</label>
            <input className="form-row-field"
                   value={this.state.accountRecommendationBalance ?? ""}
                   type="text" readOnly/>
          </Col>
          <Col>
            <label className="form-row-label">{S.deposit}</label>
            <input className="form-row-field"
                   value={this.state.accountRecommendationDeposit ?? ""}
                   type="text" readOnly/>
          </Col>
        </Row>

        <Spacer height={12}/>
        <EfficiencyMeterRow marketConditions={this.state.marketConditions}
                            label={"Market Efficiency"}/>

        {/*pot lock status*/}
        <div style={{marginTop: "16px"}}/>
        <LockStatus/>

        {/*disconnect button*/}
        <div style={{marginTop: "32px"}}/>
        <Button variant="light" onClick={() =>
          OrchidAPI.shared().provider.disconnect()
        }>{"Disconnect Provider"}</Button>
      </Container>
    )
  }
}

