import {intl} from "../index";

export {}

declare global {
  interface Number {
    toFixedLocalized(decimals: number, useGrouping?: boolean): string;
  }
}

(Number.prototype as any).toFixedLocalized = function (decimals: number, useGrouping?: boolean): string {
  return intl.formatNumber(this, {
    maximumFractionDigits: decimals,
    minimumFractionDigits: 1,
    useGrouping: useGrouping ?? false,
  });
};
