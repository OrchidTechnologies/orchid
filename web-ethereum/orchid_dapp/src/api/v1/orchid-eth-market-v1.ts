import {
  AccountRecommendation,
  MarketConditions,
  MarketConditionsSource
} from "../orchid-market-conditions";
import {LotteryPot, OrchidEthereumAPI} from "../orchid-eth";
import {GasFunds, LotFunds} from "../orchid-eth-token-types";
import {OrchidContractV1} from "./orchid-eth-contract-v1";
import {MarketConditionsSourceImplV0} from "../v0/orchid-eth-market-v0";

export class MarketConditionsSourceImplV1 implements MarketConditionsSource {
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

  async forBalance(balance: LotFunds, escrow: LotFunds): Promise<MarketConditions> {
    let {lotCostToRedeem} = await this.getCostToRedeemTicket();
    return MarketConditionsSourceImplV0.forBalance(balance, escrow, lotCostToRedeem );
  }

  // Return the cost in gas funds required to redeem a ticket and the equivalent cost in lottery token funds
  async getCostToRedeemTicket(): Promise<{ gasCostToRedeem: GasFunds; lotCostToRedeem: LotFunds }> {
    let gasPrice: GasFunds = await this.eth.getGasPrice();
    let gasCostToRedeem: GasFunds = gasPrice.multiply(OrchidContractV1.redeem_ticket_max_gas);
    // For v1 these will be the same token.
    if (this.eth.gasTokenType.symbol !== this.eth.fundsTokenType.symbol) { throw Error() }
    let lotCostToRedeem: LotFunds = this.eth.fundsTokenType.fromInt(gasCostToRedeem.intValue);
    return {gasCostToRedeem, lotCostToRedeem};
  }

  public recommendationEfficiency: number = 0.5; // 50%
  public recommendationBalanceFaceValues: number = 1.0;

  recommendedAccountComposition(): Promise<AccountRecommendation> {
    let recommendationEfficiency: number = 0.5; // 50%
    let recommendationBalanceFaceValues: number = 1.0;
    return this.getAccountRecommendation(recommendationEfficiency, recommendationBalanceFaceValues);
  }

  minViableAccountComposition(): Promise<AccountRecommendation> {
    let minViableEfficiency: number = 0.01; // 1%,
    let minViableBalanceFaceValues: number = 1;
    return this.getAccountRecommendation(minViableEfficiency, minViableBalanceFaceValues);
  }
}
