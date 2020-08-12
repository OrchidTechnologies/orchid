import React, {useEffect, useState} from "react";
import './Overview.css';
import {hashPath} from "../../util/util";
import {OrchidAPI} from "../../api/orchid-api";
import {OverviewEarn} from "./OverviewEarn";
import {OverviewDefault} from "./OverviewDefault";
import {OverviewQuickSetup} from "./OverviewQuickSetup";
import {TransactionStatus} from "../TransactionProgress";
import {S} from "../../i18n/S";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export interface OverviewProps {
  noAccount?: boolean,
  walletEthEmpty?: boolean
  walletOxtEmpty?: boolean
  potFunded?: boolean
  minFundedBalance: BigInt
  minFundedDeposit: BigInt
}

// Set the min balance and deposit considered funded.
// const minFundedBalance = oxtToKeiki(20.0);
// const minFundedDeposit = oxtToKeiki(10.0);
const minFundedBalance = BigInt(1); // allow anything greater than zero
const minFundedDeposit = BigInt(1);

export const Overview: React.FC = () => {
  const [newUser, setNewUser] = useState<boolean | undefined>(undefined);
  const [walletEthEmpty, setWalletEthEmpty] = useState<boolean | undefined>(undefined);
  const [walletOxtEmpty, setWalletOxtEmpty] = useState<boolean | undefined>(undefined);
  const [potFunded, setPotFunded] = useState<boolean | undefined>(undefined);

  // The result of any recent (in-memory transient) quick setup transaction.
  const [quickSetupResultTx, setQuickSetupResultTx] = useState<TransactionStatus | undefined>(undefined);
  // For testing:
  // const [quickSetupResultTx, setQuickSetupResultTx] = useState<TransactionStatus | undefined>(
  //   TransactionStatus.result("0x1234", S.transactionComplete,
  //     new Signer(new Wallet(), "0x12345", "12345"))
  // );

  useEffect(() => {
    let api = OrchidAPI.shared();
    let newSubscription = api.newUser_wait.subscribe(setNewUser);
    let lotSubscription = api.lotteryPot.subscribe(pot => {
      if (pot == null) {
        setPotFunded(false);
      } else {
        setPotFunded(pot.balance >= minFundedBalance && pot.escrow >= minFundedDeposit);
      }
    });
    // Note: Don't rely on the lottery pot subscription for wallet info
    let walletSubscription = api.wallet_wait.subscribe(wallet => {
      setWalletOxtEmpty(wallet.oxtBalance <= BigInt(0));
      setWalletEthEmpty(wallet.ethBalance <= BigInt(0));
    });
    return () => {
      newSubscription.unsubscribe();
      lotSubscription.unsubscribe();
      walletSubscription.unsubscribe();
    };
  }, []);

  let props: OverviewProps = {
    noAccount: newUser,
    walletEthEmpty: walletEthEmpty,
    walletOxtEmpty: walletOxtEmpty,
    potFunded: potFunded,
    minFundedBalance: minFundedDeposit,
    minFundedDeposit: minFundedDeposit
  };

  const [initialPath] = useState(hashPath());

  // Show a loading message while waiting for account status
  if (newUser !== true && potFunded === undefined) {
    return <OverviewLoading/>
  }

  if (initialPath === "#earn") {
    return <OverviewEarn {...props}/>;
  } else {
    let {noAccount, walletEthEmpty, walletOxtEmpty} = props;
    // console.log(`overview, noAccount=${noAccount}, potFunded=${potFunded}, walletEthEmpty=${walletEthEmpty}, walletOxtEmpty=${walletOxtEmpty}`)
    // If the user is ready to fund a new account or has a quick setup transaction result send to quick setup.
    if ((noAccount && !walletEthEmpty && !walletOxtEmpty) || quickSetupResultTx) {
      return <OverviewQuickSetup
        initialTxStatus={quickSetupResultTx} {...props}
        txResultSetter={setQuickSetupResultTx}
      />;
    } else {
      return <OverviewDefault {...props}/>;
    }
  }
};

export const OverviewLoading: React.FC = () => {
  return <div style={{textAlign: 'center', marginTop: '24px'}}>{S.checkingWalletStatus}...</div>
};
