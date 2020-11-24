import {min, OXT} from "./orchid-types";

export class OrchidLottery {
  // The default ticket win probility
  static ticketWinProbability = 1e-5

  // This is an artifact of the implementation that limits tha maximum balance to deposit ratio
  // for which we can display expected value results.
  static maxPrecomputedEFRatio = 15

  //
  // Estimate the survival probability for Orchid accounts given:
  // n -- number of nanopayments sent
  // p -- winrate of a nanopayment
  // F -- face value backing a nanopayment
  // E -- initial payment escrow (lottery pot balance)
  //
  static psurv(n: number, p: number, F: number, E: number): number {
    return 1 - OrchidLottery.pbust(n, p, F, E)
  }

  // Return a table of the expected number of tickets that can be written on an account
  // with the default ticket winrate and various account composition ratios.
  static getAccountSurvivalTable(): Array<number> {
    //const memoizedValue = useMemo(() => OrchidLottery._generateAccountSurvivalTable(), []);
    if (!this._table) {
      this._table = this._generateAccountSurvivalTable();
    }
    return this._table
  }

  // The expected number of tickets that can be written at the default ticket win rate and default
  // survival probabilty target. Returns null if the value cannot be determined.
  static expectedTickets(balance: OXT, deposit: OXT): number | null {
    let table = this.getAccountSurvivalTable();
    let efRatio = Math.floor(balance.floatValue / this.maxTicketFaceValue(balance, deposit).floatValue);
    return efRatio < table.length ? table[efRatio] : null
  }

  // The expected cumulative value of tickets that can be written with this account composition
  // at the expected ticket count.
  static expectedTicketValue(balance: OXT, deposit: OXT): OXT | null {
    let n = this.expectedTickets(balance, deposit);
    return n ?
      this.maxTicketFaceValue(balance, deposit).multiply(n).multiply(this.ticketWinProbability)
      : null;
  }

  private static pbust(n: number, p: number, F: number, E: number): number {
    function D(p: number, q: number) {
      let result = p * Math.log(p / q) + (1 - p) * Math.log((1 - p) / (1 - q))
      if (isNaN(result)) { return 0 }
      return result
    }
    return Math.exp(-n * D(E / (n * F), p))
  }

  // Find n for various ratios of E/F by brute force in the appropriate range
  // and with an appropriate default ticket win rate and target survival rate.
  // (The function itself is not invertible).
  private static _generateAccountSurvivalTable(): Array<number> {
    console.log("val: computing val")
    let target_survival = 0.8 // target survival rate
    let table: Array<number> = []
    let F = 1; let p = OrchidLottery.ticketWinProbability;
    for (let E = 1; E <= this.maxPrecomputedEFRatio; E++) {
      for (let n = 1e3; n <= 1e8; n++) {
        let val = OrchidLottery.psurv(n, p, F, E);
        if (val < target_survival) {
          table[E] = n;
          console.log(E, n);
          break
        }
      }
    }
    return table;
  }

  private static _table: Array<number> | null = null

  static maxTicketFaceValue(balance: OXT, deposit: OXT): OXT {
    return min(balance, deposit.divide(2.0));
  }
}
