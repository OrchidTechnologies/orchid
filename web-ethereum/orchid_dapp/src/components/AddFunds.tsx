import React, {FC, useCallback, useContext, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {
  CancellablePromise,
  Divider,
  errorClass, makeCancelable,
  useInterval,
  Visibility
} from "../util/util";
import {TransactionProgress, TransactionStatus} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Modal, Row} from "react-bootstrap";
import './AddFunds.css'
import {EthAddress, ETH, max, OXT, USD} from "../api/orchid-types";
import {
  GasPricingStrategy, isEthAddress, keikiToOxtString, LotteryPot, Signer,
  Wallet, weiToETHString
} from "../api/orchid-eth";
import {OrchidContracts} from "../api/orchid-eth-contracts";
import {S} from "../i18n/S";
import {Orchid} from "../api/orchid";
import {AccountRecommendation, MarketConditions} from "./MarketConditionsPanel";
import {OrchidPricingAPI} from "../api/orchid-pricing";
import {colorForEfficiency, EfficiencyMeter} from "./EfficiencyMeter";
import {EfficiencySlider} from "./EfficiencySlider";
import antsImage from '../assets/ants.svg'
import {AccountQRCode} from "./AccountQRCode";
import {Subscription} from "rxjs";
import {Route, RouteContext} from "./Route";
import {WalletProviderState} from "../api/orchid-eth-web3";
import {OrchidLottery} from "../api/orchid-lottery";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const CreateAccount: FC = (props) => {
  return <AddOrCreate createAccount={true}/>
}
export const AddFunds: FC = (props) => {
  return <AddOrCreate createAccount={false}/>
}

interface AddOrCreateProps {
  createAccount: boolean
}

const AddOrCreate: FC<AddOrCreateProps> = (props) => {

  // Create account state
  const [newSignerAddress, setNewSignerAddress] = useState<EthAddress | null>(null);
  const [signerKeyError, setSignerKeyError] = useState(true);

  // Existing account state
  const [wallet, setWallet] = useState<Wallet | null>(null);
  const [pot, setPot] = useState<LotteryPot | null>(null);
  const [potMarketConditions, setPotMarketConditions] = useState<MarketConditions | null>(null);

  // Form state: User entered values
  const [userEnteredBalance, setUserEnteredBalance] = useState<OXT | null>(null);
  const [editingBalance, setEditingBalance] = useState(false);
  const [userEnteredDeposit, setUserEnteredDeposit] = useState<OXT | null>(null);
  const [editingDeposit, setEditingDeposit] = useState(false);
  // TODO: We should probably do this for consistency:
  //const [userEnteredEfficiencySliderValue, setUserEnteredEfficiencySliderValue] = useState<number | null>(null);

  // Form state: Controlled values
  // TODO: addXXX is derived state that can be removed now.
  const [addBalance, setAddBalance] = useState<OXT | null>(null); // OXT
  const [addDeposit, setAddDeposit] = useState<OXT | null>(null); // OXT
  const [balanceError, setBalanceError] = useState(props.createAccount);
  const [escrowError, setEscrowError] = useState(props.createAccount);
  const [tx, setTx] = useState(new TransactionStatus());
  const txResult = React.createRef<TransactionProgress>();

  const [efficiencySliderValue, setEfficiencySliderValue] = useState<number | null>(null);
  const [accountRecommendation, setAccountRecommendation] = useState<AccountRecommendation | null>(null);
  const [showSignerAddressInstructions, setShowSignerAddressInstructions] = useState(false);
  const [generatedSigner, setGeneratedSigner] = useState<Signer | null>(null);
  const [generatingSigner, setGeneratingSigner] = useState(false);

  const [sizePickerValue, setSizePickerValue] = useState<number | null>(null);

  let {setRoute} = useContext(RouteContext);

  // Initialization
  useEffect(() => {
    let api = OrchidAPI.shared();
    let walletSubscription: Subscription = api.wallet.subscribe(wallet => {
      //console.log("addfunds: add funds got wallet: ", wallet);
      setWallet(wallet ?? null)
    });

    // Default to recommended efficiency for create
    let getRecommendedPromise: CancellablePromise<AccountRecommendation> | null
    if (props.createAccount) {
      (async () => {
        try {
          getRecommendedPromise = makeCancelable(Orchid.recommendedAccountComposition());
          setAccountRecommendation(await getRecommendedPromise.promise);
          setEfficiencySliderValue(Orchid.recommendationEfficiency * 100)
        } catch (err) {
          if (err.isCanceled) {
            //console.log("addfunds: fetch recommended account cancelled")
          } else {
            console.log("addfunds: unable to fetch recommended account composition")
          }
        }
      })();
    }

    // Subscribe to current account info for add
    let potSubscription: Subscription | null = null
    if (!props.createAccount) {
      potSubscription = api.lotteryPot.subscribe(async pot => {
        setPot(pot)
      })
    }

    // Prime other data sources
    try {
      OrchidPricingAPI.shared().getPricing().then().catch(e => {
      });
      api.eth.getGasPrice().then().catch(e => {
      });
    } catch (err) {
      console.log("addfunds: error priming data sources")
    }

    return () => {
      getRecommendedPromise?.cancel();
      potSubscription?.unsubscribe();
      walletSubscription.unsubscribe();
    };
  }, [props.createAccount]);

  // Update market conditions for the current account (if any)
  // (This is wrapped in useCallback to allow it to be used from both useInterval and useEffect below.)
  const fetchMarketConditions = useCallback(async () => {
    //console.log("addfunds: fetch market conditions");
    if (pot == null) {
      setPotMarketConditions(null);
      return;
    }
    // TODO: This needs to be cancellable
    // Market conditions for prospective pot composition
    const mc = await MarketConditions.forBalance(
      OXT.fromKeiki(pot.balance), OXT.fromKeiki(pot.escrow));
    setPotMarketConditions(mc);

    // Default the efficiency picker for the user's current account
    if (efficiencySliderValue == null) {
      //console.log("addfunds: setting efficiency slider")
      setEfficiencySliderValue(mc?.efficiency * 100 ?? 0)
    }

    // Default the size ratio picker for the user's current account if reasonable
    if (sizePickerValue == null) {
      const current = currentPotRatio()
      setSizePickerValue(current <= OrchidLottery.maxPrecomputedEFRatio ? current : 1)
    }

  }, [pot, efficiencySliderValue, sizePickerValue]);

  // Fetch market conditions when the pot changes
  useEffect(() => {
    fetchMarketConditions().then().catch(e => {
    });
  }, [fetchMarketConditions, pot])

  // Fetch market conditions periodically
  useInterval(() => {
    fetchMarketConditions().then().catch(e => {
    });
  }, 15000);

  // TODO: throttle this
  // Manage the account composition recommendation, updating it on user changes to the efficiency
  // and size pickers.  The user's current balance and deposit put a floor on the recommendation.
  //   (desired efficiency, desired size ratio) => nominal recommendation
  //   recommendation = max(nominal recommendation, user pot values)
  useEffect(() => {
    const minEfficiencyChange = 3.0; // perc
    (async () => {
      // Get the account recommendation for the efficiency and size picker values
      let recommendation: AccountRecommendation
      try {
        recommendation = await MarketConditions.getAccountRecommendation(
          (efficiencySliderValue ?? (Orchid.recommendationEfficiency * 100.0)) / 100.0,
          sizePickerValue ?? Orchid.recommendationBalanceFaceValues
        )
      } catch (err) {
        console.log("addfunds: unable to fetch market conditions: ", err)
        return;
      }

      // If we don't have an account yet just go with the recommended values
      if (pot == null || efficiencySliderValue == null || sizePickerValue == null || potMarketConditions == null) {
        setAccountRecommendation(recommendation);
        return;
      }

      // We have an account so take into account current balances in the recommendation.
      const minChange =
        Math.abs(efficiencySliderValue - potMarketConditions.efficiency * 100) < minEfficiencyChange
        && sizePickerValue === currentPotRatio();
      if (minChange) {
        // We are within the min efficiency change just put the original values back.
        setAccountRecommendation(
          new AccountRecommendation(
            OXT.fromKeiki(pot.balance),
            OXT.fromKeiki(pot.escrow),
            ETH.zero, USD.zero));
      } else {
        // recommend the higher of recommended or current balances
        setAccountRecommendation(
          new AccountRecommendation(
            max(recommendation.balance, OXT.fromKeiki(pot.balance)),
            max(recommendation.deposit, OXT.fromKeiki(pot.escrow)),
            recommendation.txEth, recommendation.txUsd)
        );
      }
    })();
  }, [efficiencySliderValue, sizePickerValue, pot, potMarketConditions])

  // Handle user entered values.
  // user entered values, account recommendation => slider value
  // TODO: The "add" amounts are derived state that we can get rid of now.
  useEffect(() => {
    if (userEnteredBalance != null) {
      // We have a user entered desired balance amount
      setAddBalance(
        max(OXT.zero, userEnteredBalance.subtract(pot?.balanceOXT ?? OXT.zero))
      );
    } else {
      // Use the recommendation
      if (accountRecommendation != null) {
        setAddBalance(
          max(OXT.zero, accountRecommendation.balance.subtract(pot?.balanceOXT ?? OXT.zero))
        );
      } else {
        setAddBalance(null);
      }
    }

    if (userEnteredDeposit != null) {
      // We have a user entered desired deposit amount
      setAddDeposit(
        max(OXT.zero, userEnteredDeposit.subtract(pot?.escrowOXT ?? OXT.zero))
      );
    } else {
      if (accountRecommendation != null) {
        setAddDeposit(
          max(OXT.zero, accountRecommendation.deposit.subtract(pot?.escrowOXT ?? OXT.zero))
        );
      } else {
        setAddDeposit(null);
      }
    }

    // Update efficiency slider for the new values
    if (userEnteredBalance != null || userEnteredDeposit != null) {
      let newBalance: OXT = userEnteredBalance ?? (accountRecommendation?.balance ?? OXT.zero);
      let newDeposit: OXT = userEnteredDeposit ?? (accountRecommendation?.deposit ?? OXT.zero);
      (async () => {
        const mc = await MarketConditions.forBalance(newBalance, newDeposit);
        //console.log("update slider for user entered values: ", newBalance, newDeposit, mc.efficiency * 100);
        setEfficiencySliderValue(mc.efficiency * 100)
      })();
    }

  }, [userEnteredBalance, userEnteredDeposit, accountRecommendation, pot])

  // Validate the balance and deposit form fields
  useEffect(() => {
    let walletBalance: OXT = wallet?.oxtBalanceOXT ?? OXT.zero;
    // console.log("validate: ", addAmount, addEscrow)

    // let totalSpend: BigInt = BigInt(oxtToKeiki(addBalance || 0)).add(oxtToKeiki(addDeposit || 0))
    let totalSpend: OXT = (addBalance || OXT.zero).add(addDeposit || OXT.zero);

    // console.log("total spend = ", BigInt(totalSpend) / 1e18)
    let overSpend = totalSpend.gt(walletBalance);
    // console.log("overspend = ", overSpend)
    // let escrowEmpty = addEscrow == null || addEscrow === 0;
    // let amountEmpty = addAmount == null || addAmount === 0;
    // let missingRequiredAmount = (props.createAccount || escrowEmpty) && amountEmpty;
    //setAmountError(missingRequiredAmount || overSpend);
    setBalanceError(overSpend);
    // let missingRequiredEscrow = (props.createAccount || amountEmpty) && escrowEmpty;
    //setEscrowError(missingRequiredEscrow || overSpend);
    setEscrowError(overSpend);
  }, [wallet, addBalance, addDeposit])

  async function submitAddFunds() {
    let api = OrchidAPI.shared();
    if (!wallet) {
      return;
    }
    let walletAddress = wallet.address;
    let walletBalance = wallet.oxtBalance
    console.log("submit add funds: ", walletAddress, addBalance, addDeposit);

    let signerAddress =
      props.createAccount ?
        (generatedSigner?.address ?? newSignerAddress)
        : (api.signer.value?.address)

    if (walletAddress == null || signerAddress == null || walletBalance == null) {
      return;
    }
    if (props.createAccount && (addBalance == null || addDeposit == null)) {
      return;
    }

    setRoute(Route.CreateAccount); // Keep the user on this page until further navigation
    setTx(TransactionStatus.running());
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    try {
      const amountKeiki = addBalance?.keiki || BigInt.zero;
      const escrowKeiki = addDeposit?.keiki || BigInt.zero;

      // Choose a gas price
      let medianGasPrice: ETH = await api.eth.getGasPrice();
      let gasPrice = GasPricingStrategy.chooseGasPrice(
        OrchidContracts.add_funds_total_max_gas, medianGasPrice, wallet.ethBalance);
      if (!gasPrice) {
        console.log("addfunds: gas price potentially too low.");
      }

      let txId = await api.eth.orchidAddFunds(
        walletAddress, signerAddress, amountKeiki, escrowKeiki, walletBalance, gasPrice);

      if (props.createAccount) {
        await api.updateSigners();
      } else {
        await api.updateLotteryPot();
      }
      setTx(TransactionStatus.result(txId, S.transactionComplete));
      api.updateWallet().then().catch(e => {
      });
      api.updateTransactions().then();
    } catch (err) {
      setTx(TransactionStatus.error(`${S.transactionFailed}: ${err}`));
      throw err
    }
  }

  // Handle user input in the signer key field
  function signerKeyInputChanged(e: any) {
    setGeneratedSigner(null)
    const address = e.currentTarget.value
    const valid = isEthAddress(address)
    setNewSignerAddress(valid ? address : null)
    setSignerKeyError(!valid)
  }

  // Generate a new signer for the user
  async function generateSigner() {
    setGeneratingSigner(true)
    if (wallet == null) {
      return
    }
    // defer this expensive operation a bit so that the button can show the disabled state.
    setTimeout(() => {
      console.log("set interval")
      const signer = OrchidAPI.shared().eth.orchidCreateSigner(wallet)
      setGeneratedSigner(signer)
      setGeneratingSigner(false)
    }, 500);
    setSignerKeyError(false)
  }

  // return the current user balance/escrow ratio or zero if undefined
  function currentPotRatio(): number {
    if (!pot?.balance || !pot.escrow || pot.escrow === BigInt(0)) {
      return 0
    }
    // escrow is two face values
    return Math.floor(BigInt(pot.balance).divide(BigInt(pot.escrow).divide(2)));
  }

  ///
  /// Render
  ///

  // Begin: logging (can be removed)
  /*
  let expectedTicketValue = accountRecommendation?.expectedTicketValue
  let expectedTickets = accountRecommendation?.expectedTickets
  let efRatio = Math.floor((accountRecommendation?.balance.value ?? 1) / (accountRecommendation?.maxFaceValue.value ?? 1));
  console.log(
    "size picker value = ", sizePickerValue,
    ", balance = ", accountRecommendation?.balance.value,
    ", deposit = ", accountRecommendation?.deposit.value,
    ", ratio = ", efRatio,
    ", expectedTickets = ", expectedTickets,
    ", expectedTicketValue = ", expectedTicketValue?.value)
  // End: logging
   */

  let totalSpend: OXT = (addBalance ?? OXT.zero).add(addDeposit ?? OXT.zero)
  let submitEnabled =
    wallet !== null
    && !tx.isRunning()
    && !(balanceError || escrowError)
    && (addBalance != null || addDeposit != null)
    && totalSpend.gt(OXT.zero)
    // create account needs a signer key
    && !(props.createAccount && signerKeyError)
    // need pot info unless we are creating an account
    && (pot != null || props.createAccount)
  ;

  function formatOxt(oxt: OXT | null): string | null {
    return oxt?.floatValue.toFixedLocalized(2).replace(/,/g, '') ?? null
  }

  let newBalanceStr = formatOxt(userEnteredBalance)
    ?? (formatOxt(accountRecommendation?.balance ?? null) ?? null)
  let newDepositStr = formatOxt(userEnteredDeposit)
    ?? (formatOxt(accountRecommendation?.deposit ?? null) ?? null)

  const maxEfficiency = 99.0;
  let totalOXTRequired: OXT | null = (addBalance != null && addDeposit != null) ?
    addBalance.add(addDeposit) : null
  // console.log(`totalOXTRequired = ${totalOXTRequired}, addBalance = ${addBalance?.keiki}, addDeposit = ${addDeposit?.keiki}`);
  const estGas: number | null =
    (totalOXTRequired === null || totalOXTRequired.floatValue === 0) ? 0
      : (accountRecommendation?.txEth.floatValue ?? null)

  const warnOXT = OXT.fromKeikiOrDefault(wallet?.oxtBalance, OXT.zero)
    .lt(totalOXTRequired ?? OXT.zero)
  const warnETH = ETH.fromWei(wallet?.ethBalance ?? BigInt(0))
    .lt(accountRecommendation?.txEth ?? ETH.zero)

  let provider = OrchidAPI.shared().eth.provider;
  let walletConnected =
    provider.walletStatus.value.state === WalletProviderState.Connected
    && provider.walletStatus.value.isMainNet()

  let generateSignerEnabled = !generatingSigner && walletConnected

  return (
    <Container className="form-style">
      <label className="title">{props.createAccount ? S.createNewAccount : S.addFunds}</label>

      {props.createAccount ?
        /*New Account Signer Address*/
        <NewAccountPanel
          signerKeyError={signerKeyError}
          signerKeyChange={signerKeyInputChanged}
          showSignerAddressInstructions={() => setShowSignerAddressInstructions(true)}
          generatedSigner={generatedSigner}
          enabled={generateSignerEnabled}
          generateSigner={generateSigner}
        />
        :
        /*Existing Orchid Account*/
        <OrchidAccountPanel pot={pot} marketConditions={potMarketConditions}/>
      }

      <Divider noGutters={true} marginTop={16}/>

      {/*funder wallet*/}
      <FunderWalletPanel wallet={wallet} warnOXT={warnOXT} warnETH={warnETH}/>
      <Divider noGutters={true} marginTop={16}/>

      {/*efficiency picker*/}
      <label className="title subheading">{"Pick your efficiency"}</label>
      <label style={{fontSize: 16, marginBottom: 32}}>
        Efficiency is determined by balance, deposit, and current market conditions.
        The suggested minimum efficiency is <b>50%</b>.
      </label>

      <EfficiencySlider
        enabled={walletConnected}
        faded={(efficiencySliderValue ?? 0) < (potMarketConditions?.efficiency ?? 0.0) * 100.0}
        value={efficiencySliderValue}
        // minValue={currentMarketConditions?.efficiency == null ? undefined : currentMarketConditions.efficiency * 100.0}
        onChange={changeEvent => {
          // Clear the user entered values and set the slider value
          setUserEnteredBalance(null);
          setUserEnteredDeposit(null);
          setEfficiencySliderValue(Math.min(parseFloat(changeEvent.target.value), maxEfficiency));
        }}/>

      {/*deposit field*/}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>{"New Deposit"}<span className={errorClass(escrowError)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onChange={(e) => {
              setUserEnteredDeposit(OXT.fromString(e.currentTarget.value) ?? OXT.zero);
              // When the user enters one value adopt the corresponding pot value
              if (!userEnteredBalance && accountRecommendation?.balance) {
                setUserEnteredBalance(accountRecommendation?.balance)
              }
            }}
            type="number"
            value={editingDeposit ? undefined : newDepositStr || (0).toFixedLocalized(2)}
            onFocus={(e) => setEditingDeposit(true)}
            onBlur={(e) => setEditingDeposit(false)}
          />
        </Col>
      </Row>

      {/*deposit instructions*/}
      <p className="instructions">
        {S.yourDepositSecuresAccessInstruction}&nbsp;{/*efficiencyText*/}
      </p>

      <Divider noGutters={true} marginTop={16}/>

      <label className="title subheading">{"Pick your size"}</label>
      <label style={{fontSize: 16, marginBottom: 0}}>
        {/*Based on current market stats and selected account ratio of {sizePickerValue ?? "..."}, */}
        {/*we estimate with 80%+ probability you will receive OXT value greater than:*/}
        Account size is the ratio of your account balance to half of your deposit size.
      </label>

      {/*size picker*/}
      <SizePicker
        value={sizePickerValue ?? 0}
        label={
          // formatOxt(accountRecommendation?.expectedTicketValue ?? null) ?? "..."
          sizePickerValue?.toString() ?? "..."
        }
        min={1}
        max={OrchidLottery.maxPrecomputedEFRatio}
        sizeChanged={setSizePickerValue}
      />

      <p className="instructions" style={{marginBottom: 16}}>
        This ratio limits the number of payments that can be made with the account and
        affects its longevity, subject to both the random nature of the payment system
        and market conditions.
      </p>

      {/*balance field*/}
      <Row className="form-row" noGutters={true}>
        <Col>
          <label>{"New Balance"}<span
            className={errorClass(balanceError)}> *</span></label>
        </Col>
        <Col>
          <input
            className="editable"
            onChange={(e) => {
              setUserEnteredBalance(OXT.fromString(e.currentTarget.value) ?? OXT.zero);
              // When the user enters a balance value adopt the corresponding pot value
              if (!userEnteredDeposit && accountRecommendation?.deposit) {
                setUserEnteredDeposit(accountRecommendation?.deposit)
              }
              return true;
            }}
            type="number"
            value={editingBalance ? undefined : newBalanceStr || (0).toFixedLocalized(2)}
            onFocus={(e) => setEditingBalance(true)}
            onBlur={(e) => setEditingBalance(false)}
          />
        </Col>
      </Row>

      <Divider noGutters={true} marginTop={16}/>

      {/*Totals*/}
      <Row className="total-row" noGutters={true}>
        <Col>
          <label>{"Total OXT"}</label>
        </Col>
        <Col>
          <div className="oxt-1">{
            totalOXTRequired?.floatValue.toFixedLocalized(4) ?? "..."
          }</div>
        </Col>
      </Row>
      <Row className="total-row nomargin" noGutters={true}>
        <Col>
          <label>{"ETH Network Fee"}</label>
        </Col>
        <Col>
          <div className="oxt-1">{estGas?.toFixedLocalized(4) ?? "..."}</div>
        </Col>
      </Row>

      <SubmitButton onClick={() => submitAddFunds()} enabled={submitEnabled}>
        {props.createAccount ? S.createAccount : S.addOXT}
      </SubmitButton>

      <TransactionProgress ref={txResult} tx={tx}/>

      <SignerAddressInstructions
        show={showSignerAddressInstructions}
        onHide={() => setShowSignerAddressInstructions(false)}
      />
    </Container>
  );
};

function OrchidAccountPanel(props: { pot: LotteryPot | null, marketConditions: MarketConditions | null }) {
  return <>
    <Divider noGutters={true}/>
    <label className="title subheading">{"Orchid Account"}</label>
    {/*balance*/}
    <Row className="form-row">
      <Col>
        <label>{S.balance}</label>
      </Col>
      <Col>
        <div className="oxt-1-pad">
          {props.pot?.balance == null ? "..." : keikiToOxtString(props.pot.balance, 2)}
        </div>
      </Col>
    </Row>
    {/*deposit*/}
    <Row className="form-row">
      <Col>
        <label>{S.deposit}</label>
      </Col>
      <Col>
        <div className="oxt-1-pad">
          {props.pot?.escrow == null ? "..." : keikiToOxtString(props.pot.escrow, 2)}
        </div>
      </Col>
    </Row>
    {/*efficiency meter*/}
    <Row className="form-row" style={{marginTop: 8}}>
      <Col>
        <label
          style={{color: colorForEfficiency(props.marketConditions?.efficiency || null)}}>{"Current Efficiency"}</label>
      </Col>
    </Row>
    <Row>
      <Col style={{marginRight: 12, marginTop: -4}}>
        <EfficiencyMeter marketConditions={props.marketConditions}/>
      </Col>
    </Row>
  </>;
}

function FunderWalletPanel(props: {
  wallet: Wallet | null,
  warnOXT: boolean,
  warnETH: boolean
}) {
  let fundTypes: string | null = null;
  if (props.warnOXT && !props.warnETH) {
    fundTypes = "OXT"
  }
  if (!props.warnOXT && props.warnETH) {
    fundTypes = "ETH"
  }
  if (props.warnOXT && props.warnETH) {
    fundTypes = "OXT and ETH"
  }
  const warning: string | null = fundTypes ?
    "You'll need additional " + fundTypes + " to complete the add funds transaction." : null

  return <>
    <div className={"funder-panel"}>
      <Row>
        <Col><label>{"Funder Wallet"}</label></Col>
        <Col
          style={{overflow: 'hidden', flexGrow: 2,}}>
          <div
            style={{overflow: 'hidden', textOverflow: "ellipsis"}} className="oxt-1-pad">
            {props.wallet?.address ?? "..."}
          </div>
        </Col>
      </Row>
      <Row>
        <Col><label className={props.warnOXT ? "warn" : ""}>{"Available OXT"}</label></Col>
        <Col>
          <div className={"oxt-1-pad" + (props.warnOXT ? " warn" : "")}>
            {keikiToOxtString(props.wallet?.oxtBalance ?? null)}</div>
        </Col>
      </Row>
      <Row>
        <Col><label className={props.warnETH ? "warn" : ""}>{"Available ETH"}</label></Col>
        <Col>
          <div className={"oxt-1-pad" + (props.warnETH ? " warn" : "")}>
            {weiToETHString(props.wallet?.ethBalance ?? null)}</div>
        </Col>
      </Row>
      {fundTypes ? <p className="instructions warn">{warning}</p> : ""}
    </div>
  </>;
}

function SignerAddressInstructions(props: any) {
  return (
    <Modal
      {...props}
      size="lg"
      aria-labelledby="contained-modal-title-vcenter"
      centered
    >
      <Modal.Header closeButton>
        <strong>What is a signer address?</strong>
      </Modal.Header>
      <Modal.Body>
        <p>
          The signer address refers to one part of a key-pair that the Orchid app uses to pay for
          decentralized service. The Orchid app requires the signer key to sign valid payments, and
          Orchid DApp requires the signer address to store on-chain with account's OXT.
        </p>
        <p>
          You can generate the signer in the DApp, and then scan it into the app by linking the
          account. You can also generate the signer in the app (Android only) and then paste in the
          signer address into the DApp when you create and fund the account on-chain.
        </p>
        <div style={{textAlign: "center", marginBottom: 32, marginTop: 32}}>
          <img alt={"ants"} src={antsImage}/>
        </div>
      </Modal.Body>
    </Modal>
  );
}

// TODO: The state we have to pass in here is kind of ridiculous.
// TODO: Should we make this a memoized function in the render function so that it has access
// TODO: to the state?  That function is already too large...
function NewAccountPanel(props: {
  signerKeyError: boolean,
  signerKeyChange: (e: any) => void,
  showSignerAddressInstructions: () => void,
  generateSigner: () => void,
  enabled: boolean,
  generatedSigner: Signer | null,
}) {
  // const [editing, setEditing] = useState(false);
  return <>
    <Row>
      <Col>
        <label>
          <span>Paste a </span>
          <span className={"link-button-style"}
                onClick={(e) => {
                  props.showSignerAddressInstructions()
                }}>Signer Address</span>
          <span className={errorClass(props.signerKeyError)}> *</span>
        </label>
      </Col>
    </Row>
    <Row>
      <Col>
        <input
          className="editable address-input"
          type="text"
          placeholder={"0x..."}
          value={props.generatedSigner?.address}
          onChange={props.signerKeyChange}
          // onFocus={(e)=>setEditing(true)}
          // onBlur={(e)=>setEditing(false)}
        />
      </Col>
    </Row>
    <Row style={{alignItems: "baseline"}}>
      <Col><label>OR</label></Col>
      <Col style={{flexGrow: 2}}>
        <SubmitButton
          onClick={props.generateSigner}
          enabled={props.generatedSigner == null && props.enabled}>
          {"Generate Signer"}
        </SubmitButton>
      </Col>
    </Row>

    {/*generated signer pane*/}
    <Visibility visible={props.generatedSigner != null}>
      {/*save instructions */}
      <div className={'save-your-key'}>
        <p className={'title'}>
          <strong>Save your key now!</strong>
        </p>
        <p className={'body'}>
          Browser memory is volatile and this signer key is not stored securely. Open up the Orchid
          app
          and link this account now, or copy & paste the account keys somewhere safe.
        </p>
      </div>

      {/*account QR Code*/}
      <AccountQRCode data={props.generatedSigner?.toConfigString() ?? "invalid signer"}/>
    </Visibility>
  </>
}

function SizePicker(props: {
  value: number, min: number, max: number,
  label: string,
  sizeChanged: (size: number) => void
}) {
  return <Row
    style={{alignItems: "baseline", lineHeight: 1.2, marginBottom: 16, textAlign: "center"}}>
    <Col>
      <button
        className="size-picker-button"
        onClick={() => {
          if (props.value > props.min) {
            props.sizeChanged(props.value - 1);
          }
        }}
      >-
      </button>
    </Col>
    <Col className="size-picker-label">{
      // props.value >= props.min && props.value <= props.max ? props.label : "..."
      props.label
    }</Col>
    <Col>
      <button
        className="size-picker-button"
        onClick={() => {
          if (props.value < props.max) {
            props.sizeChanged(props.value + 1);
          }
        }}
      >+
      </button>
    </Col>
  </Row>;
}

