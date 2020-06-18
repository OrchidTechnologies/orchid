import { intl } from '../index'

export {}

declare global {
  interface Number {
    toFixedLocalized(decimals: number): string;
    // formatCurrency(value: number, suffix: string, digits?: number, ifNull?: string) : string;
  }
}

(Number.prototype as any).toFixedLocalized = function (decimals: number): string {
  return intl.formatNumber(this, { maximumFractionDigits: decimals, minimumFractionDigits: decimals })
}

/*
(Number.prototype as any).formatCurrency =
  function(suffix: string, digits: number = 2, ifNull: string = "...") : string
{
  return value.toFixedLocalized(digits) + (suffix != null ? " $suffix" : "");
};
*/
