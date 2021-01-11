import {TransactionReceipt} from "web3-core";
import {OrchidWeb3API} from "./orchid-eth-web3";
import Web3 from "web3";
import {OrchidAPI} from "./orchid-api";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

const ORCHID_ETH_TX_KEY = "orchid-eth-tx";

export enum EthereumTransactionStatus {
  PENDING, SUCCESS, FAILURE
}

export class EthereumTransaction {

  hash: string;
  requiredConfirmations: number
  confirmations: number;

  // An indication that the transaction failed or threw an error in the contract.
  failed: boolean;


  constructor(hash: string, requiredConfirmations: number, confirmations: number, failed: boolean) {
    this.hash = hash;
    this.requiredConfirmations = requiredConfirmations;
    this.confirmations = confirmations;
    this.failed = failed;
  }

  static fromReceipt(currentBlock: number, receipt: TransactionReceipt, requiredConfirmations: number): EthereumTransaction {
    let confirmations = currentBlock - receipt.blockNumber + 1;
    return new EthereumTransaction(
      receipt.transactionHash, requiredConfirmations, confirmations,
      // TODO:
      // Note: receipt.status may be undefined here, contrary to the API.
      receipt.status === false);
  }

  static pending(hash: string): EthereumTransaction {
    return new EthereumTransaction(hash,  1, 0, false);
  }

  get status(): EthereumTransactionStatus {
    if (this.failed) {
      return EthereumTransactionStatus.FAILURE;
    }
    if (this.confirmations < this.requiredConfirmations) {
      return EthereumTransactionStatus.PENDING;
    }
    return EthereumTransactionStatus.SUCCESS;
  }

  public getLink() {
    return `https://etherscan.io/tx/${this.hash}`;
  }

  public toString = (): string => {
    return `Eth TX: hash: ${this.hash}, status: ${this.status}, confirmations: ${this.confirmations}, failed: ${this.failed}`;
  }
}

export enum OrchidTransactionType {
  AddFunds, WithdrawFunds, Lock, Unlock, MoveFundsToEscrow, Reset, StakeFunds
}

/// A Orchid transaction that may be composed of multiple ETH transactions.
export class OrchidTransaction {
  // Date monitoring began
  submitted: Date;

  // The composite type of the overall transaction
  type: OrchidTransactionType;

  // The chain for this transaction
  chainId: number

  // One or more transactions that must complete for the operation to be successfull, ordered by nonce.
  transactionHashes: string [];

  constructor(submitted: Date, type: OrchidTransactionType, chainId: number, transactionHashes: string[]) {
    this.submitted = submitted;
    this.type = type;
    this.chainId = chainId;
    this.transactionHashes = transactionHashes;
  }

  // The hash of the composite transaction is defined to be the hash of the first child tx.
  get hash(): string {
    return this.transactionHashes[0];
  }

  public toString = (): string => {
    return `Orchid TX: date: ${this.submitted}, type: ${this.type}`;
  }
}


export class OrchidTransactionDetail extends OrchidTransaction {

  // Detailed transaction information, ordered by nonce.
  transactions: EthereumTransaction [];

  constructor(parent: OrchidTransaction, transactions: EthereumTransaction[]) {
    super(parent.submitted, parent.type, parent.chainId, parent.transactionHashes);
    this.transactions = transactions;
  }

// The composite status of the overall transaction
  get status(): EthereumTransactionStatus {
    if (this.transactions.some(tx => tx.status === EthereumTransactionStatus.FAILURE)) {
      return EthereumTransactionStatus.FAILURE;
    }
    if (this.transactions.some(tx => tx.status === EthereumTransactionStatus.PENDING)) {
      return EthereumTransactionStatus.PENDING;
    }
    return EthereumTransactionStatus.SUCCESS;
  }

  public toString = (): string => {
    return `Orchid TX: date: ${this.submitted}, type: ${this.type}, txs: ${this.transactions}`;
  }
}

export type OrchidTransactionMonitorListener = (transactions: OrchidTransactionDetail []) => void;

// TODO: Scope all of this per chain
/// Monitor for in-flight transactions.
/// These are persisted and then removed when the user manually dismisses them.
export class OrchidTransactionMonitor {
  readonly POLLING_INTERVAL = 3000; // ms

  listener: OrchidTransactionMonitorListener | undefined;
  timer: NodeJS.Timeout | undefined;
  lastUpdate: Date | undefined;

  initIfNeeded(listener: OrchidTransactionMonitorListener) {
    this.listener = listener;
    if (!this.timer) {
      this.timer = setInterval(() => this.interval(), 1000);
    }
  }

  /// Begin monitoring the transaction
  add(tx: OrchidTransaction) {
    let txs = this.load();
    txs.push(tx);
    this.save(txs);
    this.update();
  }

  /// Forget the transaction with the specified hash
  remove(hash: string) {
    let txs = this.load();
    txs = txs.filter(tx => tx.hash !== hash);
    this.save(txs);
    this.update();
  }

  protected load(): OrchidTransaction [] {
    try {
      let item = localStorage.getItem(ORCHID_ETH_TX_KEY);
      if (item === null) {
        return [];
      }
      let orcTxs: OrchidTransaction [] = JSON.parse(item);
      // Note: This craziness is required in order to be able to use our TypeScript computed
      // Note: property (`hash`) on the JSON deserialized objects.  We have to recreate them.
      return orcTxs.map(tx => new OrchidTransaction(tx.submitted, tx.type, tx.chainId, tx.transactionHashes));
    } catch (err) {
      console.log("Error loading monitored orchid transactions");
      return [];
    }
  }

  protected save(txs: OrchidTransaction []) {
    localStorage.setItem(ORCHID_ETH_TX_KEY, JSON.stringify(txs));
  }

  private async interval() {
    if (!this.lastUpdate || (Date.now() - this.lastUpdate.getTime()) > this.POLLING_INTERVAL) {
      try {
        await this.update();
      } catch (err) {
        console.log(err);
      }
    }
  }

  private async update() {
    this.lastUpdate = new Date();
    let orcTxs: OrchidTransaction [] = this.load();
    let orcDetailTxs: OrchidTransactionDetail [] =
      await Promise.all(orcTxs.map(async orcTx => await this.getDetail(orcTx)));
    if (this.listener) {
      this.listener(orcDetailTxs);
    }
  }

  private async getDetail(orcTx: OrchidTransaction): Promise<OrchidTransactionDetail> {
    let web3: Web3 | null = OrchidWeb3API.shared().web3;
    let ethTxs = orcTx.transactionHashes.map(async function (hash) {
      if (!web3) {
        throw Error("eth unavailable")
      }
      let receipt: TransactionReceipt = await web3.eth.getTransactionReceipt(hash);
      //console.log("transaction receipt: ", receipt);
      if (receipt) {
        let currentBlock = await web3.eth.getBlockNumber();

        // TODO: We should probably store chain info / number of required confirmations with the stored transactions
        const requiredConfirmations = OrchidAPI.shared().eth?.requiredConfirmations ?? 2;
        return EthereumTransaction.fromReceipt(currentBlock, receipt, requiredConfirmations);
      } else {
        return EthereumTransaction.pending(hash);
      }
    });
    return new OrchidTransactionDetail(orcTx, await Promise.all(ethTxs));
  }

  cancel() {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }
}

