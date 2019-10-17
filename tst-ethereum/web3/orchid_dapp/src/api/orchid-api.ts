import {Account, LotteryPot, orchidGetAccount, orchidGetLotteryPot, orchidInitEthereum} from "./orchid-eth";
import {BehaviorSubject, Observable} from "rxjs";
import {filter, flatMap} from "rxjs/operators";
import {EtherscanIO, LotteryPotUpdateEvent} from "./etherscan-io";
import {isNotNull} from "./orchid-types";

export class OrchidAPI {
  private static instance: OrchidAPI;
  private constructor() { }

  static shared() {
    if (!OrchidAPI.instance) {
      OrchidAPI.instance = new OrchidAPI();
    }
    return OrchidAPI.instance;
  }

  // Rx model
  transactions = new BehaviorSubject<LotteryPotUpdateEvent[] | null>(null);
  transactions_wait: Observable<LotteryPotUpdateEvent[]> = this.transactions.pipe(filter(isNotNull));

  account = new BehaviorSubject<Account | null>(null);
  account_wait: Observable<Account> = this.account.pipe(filter(isNotNull));

  lotteryPot = this.account_wait.pipe(
    flatMap((account: Account) => { // flatMap resolves promises
      return orchidGetLotteryPot(account.address);
    })
  );
  lotteryPot_wait: Observable<LotteryPot> = this.lotteryPot.pipe(filter(isNotNull));

  async init(): Promise<boolean> {
    // Allow init ethereum to create the web3 context for validation
    try {
      await orchidInitEthereum();
    } catch(err) {
      return false;
    }
    this.updateAccount().then();
    this.updateTransactions().then();
    return true;
  }

  async updateAccount() {
    this.account.next(await orchidGetAccount());
  }

  async updateTransactions() {
    let io = new EtherscanIO();
    let account = await orchidGetAccount();
    let events: LotteryPotUpdateEvent[] = await io.getEvents(account.address); // Pot address is now the funder address
    this.transactions.next(events);
  }

}



