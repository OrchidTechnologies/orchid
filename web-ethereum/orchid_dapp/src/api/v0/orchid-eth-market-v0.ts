import {LotteryPot, OrchidEthereumAPI} from "../orchid-eth";
import {GasFunds, LotFunds} from "../orchid-eth-token-types";
import {OrchidLottery} from "../orchid-lottery";
import {Pricing} from "../orchid-pricing";
import {OrchidPricingMainNetV0} from "./orchid-eth-pricing-v0";
import {
  AccountRecommendation,
  MarketConditions,
  MarketConditionsSource
} from "../orchid-market-conditions";
import {OrchidContractMainNetV0} from "./orchid-eth-contract-v0";

export class MarketConditionsSourceImplV0 implements MarketConditionsSource {
  eth: OrchidEthereumAPI

  constructor(eth: OrchidEthereumAPI) {
    this.eth = eth;
  }

  async for(pot: LotteryPot): Promise<MarketConditions> {
    return this.forBalance(pot.balance, pot.escrow);
  }

  /// Given a target efficiency and a desired number of face value multiples in the balance
  /// (assuming two in the deposit) recommend balance, deposit, and required ETH amounts based
  // on current market conditions.
  async getAccountRecommendation(targetEfficiency: number, balanceFaceValues: number): Promise<AccountRecommendation> {
    let {lotCostToRedeem} = await this.getCostToRedeemTicket();
    let txGasFundsRequired: GasFunds = await this.eth.getAccountCreationGasRequired();
    return MarketConditionsSourceImplV0.getAccountRecommendation(
      targetEfficiency, balanceFaceValues, lotCostToRedeem, txGasFundsRequired );
  }

  static async getAccountRecommendation(
    targetEfficiency: number,
    balanceFaceValues: number,
    lotCostToRedeemTicket: LotFunds,
    gasRequiredToCreateAccount: GasFunds
  ): Promise<AccountRecommendation>
  {
    if (targetEfficiency >= 1.0) {
      throw Error("Invalid efficiency target: cannot equal or exceed 1.0");
    }
    let faceValue: LotFunds = lotCostToRedeemTicket.divide(1.0 - targetEfficiency);
    let deposit = faceValue.multiply(2.0);
    let balance = faceValue.multiply(balanceFaceValues);
    // console.log(`MarketConditions account recommendation for:
    //     eff=${targetEfficiency}, fv=${balanceFaceValues} =
    //     balance: ${balance.floatValue}, deposit: ${deposit.floatValue}`);
    return new AccountRecommendation(balance, deposit, gasRequiredToCreateAccount);
  }

  async forBalance(balance: LotFunds, escrow: LotFunds): Promise<MarketConditions>
  {
    let {lotCostToRedeem} = await this.getCostToRedeemTicket();
    return MarketConditionsSourceImplV0.forBalance(balance, escrow, lotCostToRedeem );
  }

  static async forBalance(
    balance: LotFunds, escrow: LotFunds, lotCostToRedeem: LotFunds
  ): Promise<MarketConditions>
  {
    let limitedByBalance = balance.lte(escrow.divide(2.0));
    let maxFaceValue: LotFunds = OrchidLottery.maxTicketFaceValue(balance, escrow);
    let ticketUnderwater = lotCostToRedeem.gte(maxFaceValue);

    // value received as a fraction of ticket face value
    let efficiency = Math.max(0, maxFaceValue.subtract(lotCostToRedeem).floatValue / maxFaceValue.floatValue);

    // console.log("MarketConditions for balance: ", balance.floatValue, escrow.floatValue, " = ", lotCostToRedeem.floatValue, maxFaceValue.floatValue, ticketUnderwater, efficiency, limitedByBalance);
    return new MarketConditions(ticketUnderwater, efficiency, limitedByBalance);
  }

  // Return the cost in gas funds required to redeem a ticket and the equivalent cost in lottery token funds
  async getCostToRedeemTicket(): Promise<{ gasCostToRedeem: GasFunds; lotCostToRedeem: LotFunds }> {
    let pricing: Pricing = await OrchidPricingMainNetV0.shared().getPricing();
    let gasPrice: GasFunds = await this.eth.getGasPrice();
    let gasCostToRedeem: GasFunds = gasPrice.multiply(OrchidContractMainNetV0.redeem_ticket_max_gas);
    let lotCostToRedeem: LotFunds = pricing.gasFundsToFunds(gasCostToRedeem);
    return {gasCostToRedeem, lotCostToRedeem};
  }

  public recommendationEfficiency: number = 0.5; // 50%
  public recommendationBalanceFaceValues: number = 1.0;

  recommendedAccountComposition(): Promise<AccountRecommendation> {
    return this.getAccountRecommendation(this.recommendationEfficiency, this.recommendationBalanceFaceValues);
  }


  minViableAccountComposition(): Promise<AccountRecommendation> {
    let minViableEfficiency: number = 0.01; // 1%,
    let minViableBalanceFaceValues: number = 1;
    return this.getAccountRecommendation(minViableEfficiency, minViableBalanceFaceValues);
  }
}