/// Pricing captures exchange rates at a point in time and supports conversion.
import {USD, OXT, ETH, GWEI, min} from "./orchid-types";
import {LotteryPot} from "./orchid-eth";
import {OrchidAPI} from "./orchid-api";

export class Pricing {
  public date: Date;
  public ethToUsdRate: number;
  public oxtToUsdRate: number;

  constructor(ethToUsdRate: number, oxtToUsdRate: number) {
    this.date = new Date();
    this.ethToUsdRate = ethToUsdRate;
    this.oxtToUsdRate = oxtToUsdRate;
  }

  public toUSD(oxt: OXT): USD | null {
    return new USD(oxt.value * this.oxtToUsdRate);
  }

  public toOXT(usd: USD): OXT | null {
    return new OXT(usd.value / this.oxtToUsdRate);
  }

  ethToOxt(eth: ETH): OXT {
    return new OXT(this.oxtToUsdRate / this.ethToUsdRate * eth.value);
  }

  ethToUSD(eth: ETH): USD {
    return new USD(eth.value * this.ethToUsdRate);
  }

  toString(): string {
    return 'Pricing{date: $date, ethToUsdRate: $ethToUsdRate, oxtToUsdRate: $oxtToUsdRate}';
  }
}

/// Exchange rates
export class OrchidPricingAPI {
  private static instance: OrchidPricingAPI;

  static exchangeRatesProviderUrl = 'https://api.coinbase.com/v2/exchange-rates';

  private constructor() {
  }

  static shared() {
    if (!OrchidPricingAPI.instance) {
      OrchidPricingAPI.instance = new OrchidPricingAPI();
    }
    return OrchidPricingAPI.instance;
  }

  _lastPricing?: Pricing

  /// Get a snapshot of current pricing data at the current time.
  /// This method may return null if no pricing data is available and the UI
  /// should handle this as a routine condition by hiding displayed conversions.
  /// This method is cached for a period of time and safe to call repeatedly.
  async getPricing(): Promise<Pricing> {

    // Cache for a period of time
    const cachePeriod = 3000; // ms
    if (this._lastPricing != null && Date.now() - this._lastPricing.date.getTime() < cachePeriod) {
      return this._lastPricing;
    }

    try {
      const response: Response = await fetch(OrchidPricingAPI.exchangeRatesProviderUrl);
      if (response.status !== 200) {
        throw Error(`Error status code: ${response.status}`);
      }
      let body = await response.json();

      let rates = body['data']['rates'];
      this._lastPricing = new Pricing(
        /*ethToUsdRate:*/ parseFloat(rates['ETH']),
        /*oxtToUsdRate:*/ parseFloat(rates['OXT'])
      );
      return this._lastPricing;
    } catch (err) {
      console.log("Error fetching pricing: $err");
      throw err;
    }
  }

  static gasCostToRedeemTicket = 100000;

  /// Calculate the current real world value of the largest ticket that can be
  /// issued from this lottery pot, taking into account the amount of gas required
  /// to redeem the ticket, current gas prices, and the OXT-ETH exchange rate.
  /// Returns the net value in OXT, which may be zero or negative if the ticket
  /// would be unprofitable to redeem.
  async getMaxTicketValue(pot: LotteryPot): Promise<OXT> {
    let pricing = await this.getPricing();
    if (pricing == null) {
      throw Error("no pricing")
    }
    let gasPrice: GWEI = await OrchidAPI.shared().eth.getGasPrice();
    let gasCostToRedeem: ETH = gasPrice.multiply(OrchidPricingAPI.gasCostToRedeemTicket).toEth()
    let oxtCostToRedeem: OXT = pricing.ethToOxt(gasCostToRedeem);
    let maxFaceValue: OXT = min(
      OXT.fromKeiki(pot.balance),
      OXT.fromKeiki(pot.escrow).divide(2.0)
    );
    return maxFaceValue.subtract(oxtCostToRedeem);
  }
}

