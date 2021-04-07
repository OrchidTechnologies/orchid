import React, {FC, useCallback, useContext, useEffect, useState} from "react";
import {
  Divider,
  errorClass, useInterval,
  Visibility
} from "../util/util";
import {TransactionProgress, TransactionStatus} from "./TransactionProgress";
import {SubmitButton} from "./SubmitButton";
import {Col, Container, Modal, Row} from "react-bootstrap";
import './AddFunds.css'
import {isEthAddress, LotteryPot, Signer, Wallet} from "../api/orchid-eth";
import {S} from "../i18n/S";
import {colorForEfficiency, EfficiencyMeter} from "./EfficiencyMeter";
import {EfficiencySlider} from "./EfficiencySlider";
import antsImage from '../assets/ants.svg'
import {AccountQRCode} from "./AccountQRCode";
import {Route, RouteContext} from "./RouteContext";
import {WalletProviderState} from "../api/orchid-eth-web3";
import {OrchidLottery} from "../api/orchid-lottery";
import {AccountRecommendation, MarketConditions} from "../api/orchid-market-conditions";
import {EthAddress} from "../api/orchid-eth-types";
import {max, LotFunds, GasFunds} from "../api/orchid-eth-token-types";
import {AccountContext, ApiContext, WalletContext, WalletProviderContext} from "../index";
import {Cancellable, makeCancellable} from "../util/async-util";
import {Spacer} from "./Spacer";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export const CreateAccount: FC = () => {
  return <AddOrCreate createAccount={true}/>
}
export const AddFunds: FC = () => {
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
  const [potMarketConditions, setPotMarketConditions] = useState<MarketConditions | null>(null);

  // Form state: User entered values
  const [userEnteredBalance, setUserEnteredBalance] = useState<LotFunds | null>(null);
  const [editingBalance, setEditingBalance] = useState(false);
  const [userEnteredDeposit, setUserEnteredDeposit] = useState<LotFunds | null>(null);
  const [editingDeposit, setEditingDeposit] = useState(false);
  const [userEnteredSizePickerValue, setUserEnteredSizePickerValue] = useState<number | null>(null);
  // TODO: We should probably do this for consistency:
  //const [userEnteredEfficiencySliderValue, setUserEnteredEfficiencySliderValue] = useState<number | null>(null);

  const [sizePickerValue, setSizePickerValue] = useState<number | null>(null);

  // Form state: Controlled values
  // TODO: addXXX is derived state that can be removed now.
  const [addBalance, setAddBalance] = useState<LotFunds | null>(null);
  const [addDeposit, setAddDeposit] = useState<LotFunds | null>(null);
  const [balanceError, setBalanceError] = useState(props.createAccount);
  const [escrowError, setEscrowError] = useState(props.createAccount);
  const [tx, setTx] = useState(new TransactionStatus());
  const txResult = React.createRef<TransactionProgress>();

  const [efficiencySliderValue, setEfficiencySliderValue] = useState<number | null>(null);
  const [accountRecommendation, setAccountRecommendation] = useState<AccountRecommendation | null>(null);
  const [showSignerAddressInstructions, setShowSignerAddressInstructions] = useState(false);
  const [generatedSigner, setGeneratedSigner] = useState<Signer | null>(null);
  const [generatingSigner, setGeneratingSigner] = useState(false);


  // Contexts
  let {setRoute} = useContext(RouteContext);
  let {fundsToken, gasToken} = useContext(WalletProviderContext);
  let api = useContext(ApiContext);
  let wallet = useContext(WalletContext);
  let pot = useContext(AccountContext);

  // Initialization
  useEffect(() => {
    // Default to recommended efficiency for create
    let cancellablePromises: Array<Cancellable> = [];
    if (props.createAccount) {
      (async () => {
        try {
          if (api.eth) {
            setAccountRecommendation(
              await makeCancellable(api.eth.marketConditions.recommendedAccountComposition(), cancellablePromises).promise);
            setEfficiencySliderValue(api.eth.marketConditions.recommendationEfficiency * 100)
          }
        } catch (err) {
          if (err.isCanceled) {
            //console.log("addfunds: fetch recommended account cancelled")
          } else {
            console.log("addfunds: unable to fetch recommended account composition")
          }
        }
      })();
    }

    return () => {
      cancellablePromises.forEach(p => p.cancel());
    };
  }, [api.eth, props.createAccount]);

  // return the current user balance/escrow ratio or zero if undefined
  const currentPotRatio: () => number = useCallback(() => {
    if (!pot?.balance || !pot.escrow || pot.escrow.isZero()) {
      return 0
    }
    // escrow is two face values
    return Math.floor(pot.balance.floatValue / ((pot.escrow.floatValue) / 2));
  }, [pot]);

  // Update market conditions for the current account (if any)
  // (This is wrapped in useCallback to allow it to be used from both useInterval and useEffect below.)
  const fetchMarketConditions = useCallback(async () => {
    //console.log("addfunds: fetch market conditions");
    if (pot == null) {
      setPotMarketConditions(null);
      return;
    }
    // TODO: This needs to be cancellable (have it return the promise)
    // Market conditions for prospective pot composition
    if (api.eth) {
      const mc = await api.eth.marketConditions.forBalance(pot.balance, pot.escrow);
      setPotMarketConditions(mc);

      // Default the efficiency picker for the user's current account
      if (efficiencySliderValue == null) {
        //console.log("addfunds: setting efficiency slider")
        setEfficiencySliderValue(mc?.efficiency * 100 ?? 0)
      }
    }

    // Default the size ratio picker for the user's current account if reasonable
    if (sizePickerValue == null) {
      const current: number = currentPotRatio()
      setSizePickerValue(current <= OrchidLottery.maxPrecomputedEFRatio ? current : 1)
    }
  }, [currentPotRatio, api.eth, pot, efficiencySliderValue, sizePickerValue]);


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

  // Update account composition recommendation on user changes to the efficiency and size pickers,
  // using the user's current balance and deposit as a floor on the recommendation.
  //   (desired efficiency, desired size ratio) => nominal recommendation
  //   recommendation = max(nominal recommendation, user pot values)
  useEffect(() => {
    if (!gasToken) {
      setAccountRecommendation(null);
      return;
    }
    const minEfficiencyChange = 3.0; // perc

    // TODO: throttle this
    (async () => {
      if (!api.eth) {
        return;
      }
      // Get the account recommendation for the efficiency and size picker values
      let recommendation: AccountRecommendation
      try {
        let marketConditions = api.eth.marketConditions;
        recommendation = await marketConditions.getAccountRecommendation(
          (
            (efficiencySliderValue && efficiencySliderValue > 0 ? efficiencySliderValue : null)
            ?? (marketConditions.recommendationEfficiency * 100.0)) / 100.0,
          (userEnteredSizePickerValue ?? sizePickerValue) ?? marketConditions.recommendationBalanceFaceValues
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
        && (userEnteredSizePickerValue ?? sizePickerValue) === currentPotRatio();
      if (minChange) {
        // We are within the min efficiency change just put the original values back.
        setAccountRecommendation(new AccountRecommendation(pot.balance, pot.escrow, gasToken.zero));
      } else {
        // recommend the higher of recommended or current balances
        setAccountRecommendation(
          new AccountRecommendation(
            max(recommendation.balance, pot.balance),
            max(recommendation.deposit, pot.escrow),
            recommendation.txGasFundsRequired)
        );
      }
    })();
  }, [currentPotRatio, api.eth, efficiencySliderValue, sizePickerValue, userEnteredSizePickerValue, pot, potMarketConditions, gasToken])

  // Handle user entered balance and deposit values updating the efficiency slider and size picker to match.
  // user entered values, account recommendation => slider value, picker value
  // TODO: The "add" amounts are derived state that we can get rid of now.
  useEffect(() => {
    if (!fundsToken) {
      setAddBalance(null)
      setAddDeposit(null)
      return;
    }
    const zero = fundsToken.zero;

    if (userEnteredBalance != null) {
      // We have a user entered desired balance amount
      setAddBalance(
        max(zero, userEnteredBalance.subtract(pot?.balance ?? zero))
      );
    } else {
      // Use the recommendation
      if (accountRecommendation != null) {
        setAddBalance(
          max(zero, accountRecommendation.balance.subtract(pot?.balance ?? zero))
        );
      } else {
        setAddBalance(null);
      }
    }

    if (userEnteredDeposit != null) {
      // We have a user entered desired deposit amount
      setAddDeposit(
        max(zero, userEnteredDeposit.subtract(pot?.escrow ?? zero))
      );
    } else {
      if (accountRecommendation != null) {
        setAddDeposit(
          max(zero, accountRecommendation.deposit.subtract(pot?.escrow ?? zero))
        );
      } else {
        setAddDeposit(null);
      }
    }

    // Update efficiency slider for the new values
    if (userEnteredBalance != null || userEnteredDeposit != null) {
      let newBalance: LotFunds = userEnteredBalance ?? (accountRecommendation?.balance ?? zero);
      let newDeposit: LotFunds = userEnteredDeposit ?? (accountRecommendation?.deposit ?? zero);
      (async () => {
        if (api.eth) {
          const mc = await api.eth.marketConditions.forBalance(newBalance, newDeposit);
          //console.log("update slider for user entered values: ", newBalance, newDeposit, mc.efficiency * 100);
          setEfficiencySliderValue(mc.efficiency * 100)
        }
      })();
    }

    // Update the size picker for the new values
    if (!userEnteredSizePickerValue && pot) {
      const balance = userEnteredBalance || pot.balance
      const deposit = userEnteredDeposit || pot.escrow
      const value = Math.floor(balance.floatValue / ((deposit.floatValue) / 2));
      setSizePickerValue(value <= OrchidLottery.maxPrecomputedEFRatio ? value : 1)
    }

  }, [api.eth, fundsToken, userEnteredBalance, userEnteredDeposit, userEnteredSizePickerValue, accountRecommendation, pot])

  // Validate the balance and deposit form fields
  useEffect(() => {
    if (!fundsToken) {
      return;
    }
    const zero = fundsToken.zero;
    let walletBalance: LotFunds = wallet?.fundsBalance ?? zero;
    // console.log("validate: ", addAmount, addEscrow)

    let totalSpend: LotFunds = (addBalance || zero).add(addDeposit || zero);

    // console.log("total spend = ", BigInt(totalSpend) / 1e18)
    let overSpend = totalSpend.gt(walletBalance);
    setBalanceError(overSpend);
    setEscrowError(overSpend);
  }, [fundsToken, wallet, addBalance, addDeposit])

  async function submitAddFunds() {
    if (!wallet || !fundsToken || !api.eth) {
      return;
    }
    const zero = fundsToken.zero;
    let walletAddress = wallet.address;
    console.log("submit add funds: ", walletAddress, addBalance, addDeposit);
    let signerAddress =
      props.createAccount ?
        (generatedSigner?.address ?? newSignerAddress)
        : (api.signer.value?.address)

    if (walletAddress == null || signerAddress == null) {
      return;
    }
    if (props.createAccount && (addBalance == null || addDeposit == null)) {
      return;
    }

    setRoute(props.createAccount ? Route.CreateAccount : Route.AddFunds); // Keep the user on this page until further navigation
    setTx(TransactionStatus.running());
    if (txResult.current != null) {
      txResult.current.scrollIntoView();
    }
    try {
      const amount = addBalance ?? zero;
      const deposit = addDeposit ?? zero
      let txId = await api.eth.orchidAddFunds(walletAddress, signerAddress, amount, deposit, wallet);

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
    // defer this expensive operation a bit so that the button can show the disabled state.
    setTimeout(() => {
      if (wallet == null) {
        return
      }
      console.log("set interval")
      if (!api.eth) {
        return
      }
      const signer = api.eth.orchidCreateSigner(wallet)
      setGeneratedSigner(signer)
      setGeneratingSigner(false)
    }, 500);
    setSignerKeyError(false)
  }

  // useTraceUpdate(
  //   [currentPotRatio, api.eth, efficiencySliderValue, sizePickerValue, pot, potMarketConditions, gasToken]
  // );

  ///
  /// Render
  ///

  let totalSpend: LotFunds | null = addBalance && addDeposit ? addBalance.add(addDeposit) : null;
  let submitEnabled =
    wallet !== null
    && !tx.isRunning
    && !(balanceError || escrowError)
    && (addBalance != null || addDeposit != null)
    && (totalSpend?.gtZero() ?? false)
    // create account needs a signer key
    && !(props.createAccount && signerKeyError)
    // need pot info unless we are creating an account
    && (pot != null || props.createAccount)
  ;

  let newBalanceStr = userEnteredBalance?.toFixedLocalized()
    ?? (accountRecommendation?.balance?.toFixedLocalized() ?? null)
  let newDepositStr = userEnteredDeposit?.toFixedLocalized()
    ?? (accountRecommendation?.deposit.toFixedLocalized() ?? null)

  const maxEfficiency = 99.0;
  let totalFundsRequired: LotFunds | null = (addBalance != null && addDeposit != null) ?
    addBalance.add(addDeposit) : null

  const estGas: GasFunds | null =
    (totalFundsRequired === null || totalFundsRequired.isZero())
      ? (gasToken?.zero ?? null)
      : (accountRecommendation?.txGasFundsRequired ?? null)

  const warnFunds =
    (fundsToken && (wallet?.fundsBalance ?? fundsToken.zero).lt(totalFundsRequired ?? fundsToken.zero)) ?? false
  const warnGas =
    (gasToken && (wallet?.gasFundsBalance ?? gasToken.zero).lt(accountRecommendation?.txGasFundsRequired ?? gasToken.zero)) ?? false

  let provider = api.provider;
  let walletConnected = provider.walletStatus.value.state === WalletProviderState.Connected
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
      <FunderWalletPanel wallet={wallet} warnFunds={warnFunds} warnGas={warnGas}
                         singleToken={fundsToken?.symbol === gasToken?.symbol}/>
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
            className="editable form-style-number"
            onChange={(e) => {
              setUserEnteredDeposit(
                (fundsToken?.fromString(e.currentTarget.value) ?? fundsToken?.zero) ?? null);
              // When the user enters one value adopt the corresponding pot value
              // if (!userEnteredBalance && accountRecommendation?.balance) {
              //   setUserEnteredBalance(accountRecommendation?.balance ?? null)
              // }
            }}
            type={editingDeposit ? "number" : undefined}
            value={editingDeposit ? undefined : newDepositStr ?? fundsToken?.zero.toFixedLocalized()}
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
        Account size is the ratio of your account balance to half of your deposit size.
      </label>

      {/*size picker*/}
      <SizePicker
        value={userEnteredSizePickerValue ?? sizePickerValue ?? 0}
        label={
          (userEnteredSizePickerValue?.toString() ?? sizePickerValue?.toString()) ?? "..."
        }
        min={1}
        max={OrchidLottery.maxPrecomputedEFRatio}
        sizeChanged={size => {
          setUserEnteredBalance(null)
          setUserEnteredSizePickerValue(size)
        }}
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
            className="editable form-style-number"
            onChange={(e) => {
              setUserEnteredSizePickerValue(null)
              setUserEnteredBalance(
                (fundsToken?.fromString(e.currentTarget.value) ?? fundsToken?.zero) ?? null);
              // When the user enters a balance value adopt the corresponding pot value
              if (!userEnteredDeposit && accountRecommendation?.deposit) {
                setUserEnteredDeposit(accountRecommendation?.deposit ?? null)
              }
              return true;
            }}
            type={editingDeposit ? "number" : undefined}
            value={editingBalance ? undefined : newBalanceStr ?? fundsToken?.zero.toFixedLocalized()}
            onFocus={(e) => setEditingBalance(true)}
            onBlur={(e) => setEditingBalance(false)}
          />
        </Col>
      </Row>

      <Divider noGutters={true} marginTop={16}/>

      {/*Totals*/}
      <Row className="total-row" noGutters={true}>
        <Col>
          <label>{"Total "}{fundsToken?.symbol}</label>
        </Col>
        <Col>
          <div className="funds-1">{
            totalFundsRequired?.toFixedLocalized() ?? "..."
          }</div>
        </Col>
      </Row>
      <Row className="total-row nomargin" noGutters={true}>
        <Col>
          <label>{"Network Fee "}{gasToken?.symbol}</label>
        </Col>
        <Col>
          <div className="funds-1">{estGas?.toFixedLocalized() ?? "..."}</div>
        </Col>
      </Row>

      <Spacer height={24}/>
      <SubmitButton onClick={() => submitAddFunds()} enabled={submitEnabled}>
        {props.createAccount ? S.createAccount : S.addFunds}
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
        <div className="funds-1-pad">
          {props.pot?.balance.toFixedLocalized() ?? "..."}
        </div>
      </Col>
    </Row>
    {/*deposit*/}
    <Row className="form-row">
      <Col>
        <label>{S.deposit}</label>
      </Col>
      <Col>
        <div className="funds-1-pad">
          {props.pot?.escrow.toFixedLocalized() ?? "..."}
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
  warnFunds: boolean,
  warnGas: boolean,
  singleToken: boolean
}) {
  let {fundsToken: funds, gasToken: gas} = useContext(WalletProviderContext);

  let fundTypesText: string | null = null;
  if (props.warnFunds && !props.warnGas) {
    fundTypesText = funds?.symbol ?? "funds"
  }
  if (!props.warnFunds && props.warnGas) {
    fundTypesText = gas?.symbol ?? "funds"
  }
  if (props.warnFunds && props.warnGas) {
    if (funds?.symbol && gas?.symbol) {
      fundTypesText = `${funds.symbol} and ${gas.symbol}`
    } else {
      fundTypesText = "funds"
    }
  }
  const warning: string | null = fundTypesText ?
    "You'll need additional " + fundTypesText + " to complete a transaction." : null

  return <>
    <div className={"funder-panel"}>
      <Row>
        <Col><label>{"Funder Wallet"}</label></Col>
        <Col
          style={{overflow: 'hidden', flexGrow: 2,}}>
          <div
            style={{overflow: 'hidden', textOverflow: "ellipsis"}} className="funds-1-pad">
            {props.wallet?.address ?? "..."}
          </div>
        </Col>
      </Row>
      <Row>
        <Col><label
          className={props.warnFunds ? "warn" : ""}>{"Available "}{funds?.symbol ?? "Funds"}</label></Col>
        <Col>
          <div className={"funds-1-pad" + (props.warnFunds ? " warn" : "")}>
            {props.wallet?.fundsBalance.toFixedLocalized() ?? "..."}</div>
        </Col>
      </Row>
      <Row className={props.singleToken ? "hidden" : ""}>
        <Col><label
          className={props.warnGas ? "warn" : ""}>{"Available "}{gas?.symbol ?? "Gas Funds"}</label></Col>
        <Col>
          <div className={"funds-1-pad" + (props.warnGas ? " warn" : "")}>
            {props.wallet?.gasFundsBalance.toFixedLocalized() ?? "..."}
          </div>
        </Col>
      </Row>
      {fundTypesText ? <p className="instructions warn">{warning}</p> : ""}
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
          Orchid DApp requires the signer address to store on-chain with account's funds.
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
