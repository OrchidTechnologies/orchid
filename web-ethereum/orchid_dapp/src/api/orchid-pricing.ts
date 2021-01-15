/// Pricing captures exchange rates at a point in time and supports conversion.
import {GasFunds, LotFunds, TokenType} from "./orchid-eth-token-types";

export class USD {
  static zero: USD = new USD(0);

  // TODO: This should probably stored as int cents
  dollars: number;

  private constructor(dollars: number) {
    this.dollars = dollars;
  }

  public static fromNumber(dollars: number): USD {
    return new USD(dollars);
  }

  public lt(other: USD): boolean {
    return this.dollars < other.dollars;
  }
}

export class Pricing {
  fundsTokenType: TokenType<LotFunds>
  gasTokenType: TokenType<GasFunds>

  public date: Date;
  public lotFundsToUsdRate: number; // e.g. OXT per USD
  public gasFundsToUsdRate: number; // e.g. ETH per USD

  constructor(
    fundsTokenType: TokenType<LotFunds>,
    gasTokenType: TokenType<GasFunds>,
    gasFundsToUsdRate: number,
    lotFundsToUsdRate: number)
  {
    this.fundsTokenType = fundsTokenType;
    this.gasTokenType = gasTokenType;
    this.date = new Date();
    this.lotFundsToUsdRate = lotFundsToUsdRate;
    this.gasFundsToUsdRate = gasFundsToUsdRate;
  }

  public toUSD(val: LotFunds): USD | null {
    return USD.fromNumber(val.floatValue * this.lotFundsToUsdRate);
  }

  public toFunds(usd: USD): LotFunds | null {
    return this.fundsTokenType.fromNumber(usd.dollars / this.lotFundsToUsdRate);
  }

  gasFundsToFunds(eth: GasFunds): LotFunds {
    return this.fundsTokenType.fromNumber(this.lotFundsToUsdRate / this.gasFundsToUsdRate * eth.floatValue);
  }

  gasFundsToUsd(eth: GasFunds): USD {
    return USD.fromNumber(eth.floatValue * this.gasFundsToUsdRate);
  }
}

