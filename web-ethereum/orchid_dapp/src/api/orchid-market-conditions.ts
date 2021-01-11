/// A recommendation for account composition based on current market rates.
import {LotteryPot} from "./orchid-eth-types";
import {OrchidLottery} from "./orchid-lottery";
import {GasFunds, LotFunds} from "./orchid-eth-token-types";

export interface MarketConditionsSource {

  for(pot: LotteryPot): Promise<MarketConditions>

  /// Given a target efficiency and a desired number of face value multiples in the balance
  /// (assuming two in the deposit) recommend balance, deposit, and required ETH amounts based
  // on current market conditions.
  getAccountRecommendation(targetEfficiency: number, balanceFaceValues: number): Promise<AccountRecommendation>

  forBalance(balance: LotFunds, escrow: LotFunds): Promise<MarketConditions>

  // Return the cost in gas funds required to redeem a ticket and the equivalent cost in lottery token funds
  getCostToRedeemTicket(): Promise<{ gasCostToRedeem: GasFunds; lotCostToRedeem: LotFunds }>

  recommendedAccountComposition(): Promise<AccountRecommendation>

  recommendationEfficiency: number
  recommendationBalanceFaceValues: number

  minViableAccountComposition(): Promise<AccountRecommendation>
}

export class MarketConditions {
  public ticketUnderwater: boolean
  public efficiency: number
  public limitedByBalance: boolean

  public efficiencyPerc(): string {
    return (this.efficiency * 100).toFixed() + "%";
  }

  constructor(ticketUnderwater: boolean, efficiency: number, limitedByBalance: boolean) {
    this.ticketUnderwater = ticketUnderwater;
    this.efficiency = efficiency;
    this.limitedByBalance = limitedByBalance;
  }
}

export class AccountRecommendation {
  public balance: LotFunds;
  public deposit: LotFunds;
  public txGasFundsRequired: GasFunds; // e.g. ETH required for the funding transaction

  // The max face value of a ticket that can be written with this account composition.
  get maxFaceValue(): LotFunds {
    return OrchidLottery.maxTicketFaceValue(this.balance, this.deposit);
  }

  // The expected number of tickets that can be written with this account composition at the
  // default ticket win rate and default survival probabilty target. Returns null if the value
  // cannot be determined.
  get expectedTickets(): number | null {
    return OrchidLottery.expectedTickets(this.balance, this.deposit);
  }

  // The expected cumulative value of tickets that can be written with this account composition
  // at the expected ticket count.
  get expectedTicketValue(): LotFunds | null {
    return OrchidLottery.expectedTicketValue(this.balance, this.deposit);
  }

  constructor(balance: LotFunds, deposit: LotFunds, txEth: GasFunds) {
    this.balance = balance;
    this.deposit = deposit;
    this.txGasFundsRequired = txEth;
  }
}

