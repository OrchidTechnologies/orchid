import {removeHexPrefix} from "../util/util";
import {GasFunds, LotFunds} from "./orchid-eth-token-types";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export type EthAddress = string;
export type Secret = string;
export type TransactionId = string;

export class Wallet {
  public address: EthAddress;
  public fundsBalance: LotFunds; // e.g. OXT
  public gasFundsBalance: GasFunds; // e.g. ETH

  constructor(
    initialLotFunds: LotFunds,
    initialGasFunds: GasFunds
  ) {
    this.address = "";
    this.fundsBalance = initialLotFunds
    this.gasFundsBalance = initialGasFunds
  }
}

/// A Wallet may have many signers, each of which is essentially an "Orchid Account",
// controlling a Lottery Pot.
export class Signer {
  // The wallet with which this signer is associated.
  public wallet: Wallet;
  // The signer public address.
  public address: EthAddress;
  // The signer private key, if available.
  public secret: Secret | null;

  constructor(wallet: Wallet, address: EthAddress, secret?: Secret) {
    this.wallet = wallet;
    this.address = address;
    this.secret = removeHexPrefix(secret ?? null);
  }

  toConfigString(): string | null {
    if (!this.secret) {
      return null;
    }
    return `account={protocol:"orchid",funder:"${this.wallet.address}",secret:"${this.secret}"}`;
  }
}

export interface EthereumKey {
  address: string
  privateKey: string
}

/// A Lottery Pot containing funds against which lottery tickets are issued.
export class LotteryPot {
  public signer: Signer;
  public unlock: Date | null;
  public balance: LotFunds
  public escrow: LotFunds

  constructor(signer: Signer, balance: LotFunds, escrow: LotFunds, unlock: Date | null) {
    this.signer = signer;
    this.signer = signer;
    this.balance = balance;
    this.escrow = escrow;
    this.unlock = unlock;
  }

  get isLocked(): boolean {
    return this.unlock == null || new Date() < this.unlock;
  }

  get isUnlocked(): boolean {
    return !this.isLocked;
  }

  get isUnlocking(): boolean {
    return this.unlock != null && new Date() < this.unlock;
  }
}

export class LotteryPotUpdateEvent {
  public balance: LotFunds | null;
  public balanceChange: LotFunds | null;
  public escrow: LotFunds | null;
  public escrowChange: LotFunds | null;
  public blockNumber: number | null;
  public timeStamp: Date;
  public gasPrice: string;
  public gasUsed: number;
  public transactionHash: string;

  constructor(
    balance: LotFunds | null,
    balanceChange: LotFunds | null,
    escrow: LotFunds | null,
    escrowChange: LotFunds | null,
    blockNumber: number | null,
    timeStamp: Date,
    gasPrice: string,
    gasUsed: number,
    transactionHash: string)
  {
    this.balance = balance;
    this.balanceChange = balanceChange;
    this.escrow = escrow;
    this.escrowChange = escrowChange;
    this.blockNumber = blockNumber;
    this.timeStamp = timeStamp;
    this.gasPrice = gasPrice;
    this.gasUsed = gasUsed;
    this.transactionHash = transactionHash;
  }
}