/// Exchange rates
import {Pricing} from "../orchid-pricing";
import {EVMChains} from "../chains/chains";

export class OrchidPricingMainNetV0 {
  private static instance: OrchidPricingMainNetV0;

  static exchangeRatesProviderUrl = 'https://api.coinbase.com/v2/exchange-rates';

  private constructor() {
  }

  static shared() {
    if (!OrchidPricingMainNetV0.instance) {
      OrchidPricingMainNetV0.instance = new OrchidPricingMainNetV0();
    }
    return OrchidPricingMainNetV0.instance;
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
      const response: Response = await fetch(OrchidPricingMainNetV0.exchangeRatesProviderUrl);
      if (response.status !== 200) {
        throw Error(`Error status code: ${response.status}`);
      }
      let body = await response.json();

      let rates = body['data']['rates'];
      this._lastPricing = new Pricing(
        EVMChains.OXT_TOKEN, EVMChains.ETH_TOKEN,
        /*gasToUsdRate:*/ parseFloat(rates['ETH']),
        /*lotToUsdRate:*/ parseFloat(rates['OXT'])
      );
      return this._lastPricing;
    } catch (err) {
      console.log("Error fetching pricing: $err");
      throw err;
    }
  }
}