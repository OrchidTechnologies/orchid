import {parseFloatSafe} from "../util/util";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export type EthAddress = string;
export type Secret = string;
export type TransactionId = string;

// Helper for RxJS with Typescript
export function isNotNull<T>(a: T | null): a is T {
  return a !== null;
}

export function isDefined<T>(a: T | undefined): a is T {
  return a !== undefined;
}

export type KEIKI = BigInt // 1e18 KEIKI per OXT
export type WEI = BigInt // 1e18 WEI per ETH

export class OXT {
  static zero: OXT = new OXT(BigInt.zero);

  keiki: KEIKI;

  // The float value of the OXT
  get floatValue(): number {
    return BigInt(this.keiki).toJSNumber() / 1e18;
  }

  private constructor(keiki: KEIKI) {
    this.keiki = keiki
  }

  public multiply(other: number): OXT {
    // perform floating point multiplication
    // Note: We could take a precision here and do the arithmetic with int
    return new OXT(BigInt(Math.round(BigInt(this.keiki).toJSNumber() * other)));
  }

  public divide(other: number): OXT {
    // perform floating point division
    // Note: We could take a precision here and do the arithmetic with int
    return new OXT(BigInt(Math.round(BigInt(this.keiki).toJSNumber() / other)));
  }

  public subtract(other: OXT): OXT {
    return new OXT(BigInt(this.keiki).subtract(other.keiki));
  }

  public add(other: OXT): OXT {
    return new OXT(BigInt(this.keiki).add(other.keiki));
  }

  public lt(other: OXT): boolean {
    return BigInt(this.keiki).lt(other.keiki);
  }
  public lte(other: OXT): boolean {
    return BigInt(this.keiki).leq(other.keiki);
  }
  public gt(other: OXT): boolean {
    return BigInt(this.keiki).gt(other.keiki);
  }
  public gte(other: OXT): boolean {
    return BigInt(this.keiki).geq(other.keiki);
  }

  static fromKeiki(keiki: KEIKI): OXT {
    return new OXT(keiki);
  }

  static fromKeikiOrDefault(keiki: KEIKI | undefined, defaultValue: OXT): OXT {
    return keiki ? this.fromKeiki(keiki) : defaultValue
  }

  static fromNumber(oxt: number): OXT {
    return new OXT(BigInt(Math.round(oxt * 1e18))); // multiply prior to int conversion
  }

  static fromString(oxt: string): OXT | null {
    let floatValue = parseFloatSafe(oxt);
    // console.log(`oxt fromstring: ${oxt} = ${floatValue}, keiki value = ${OXT.fromNumber(floatValue??0).keiki}`)
    if (!floatValue) { return null; }
    return OXT.fromNumber(floatValue);
  }
}

export function min(a: OXT, b: OXT): OXT {
  return OXT.fromKeiki(BigInt.min(a.keiki, b.keiki));
}

export function max(a: OXT, b: OXT): OXT {
  return OXT.fromKeiki(BigInt.max(a.keiki, b.keiki));
}

export class ETH {
  static zero: ETH = new ETH(BigInt.zero);

  wei: WEI

  // The float value
  get floatValue(): number {
    return BigInt(this.wei).toJSNumber() / 1e18;
  }

  get floatValueGwei(): number {
    return BigInt(this.wei).toJSNumber() / 1e9;
  }

  private constructor(wei: WEI) {
    this.wei = wei
  }

  public static fromWei(wei: WEI) {
    return new ETH(wei);
  }

  public static fromWeiString(wei: string): ETH {
    return new ETH(BigInt(wei));
  }

  static fromNumberAsGwei(gwei: number): ETH {
    return new ETH(BigInt(Math.round(gwei * 1e9))); // multiply prior to int conversion
  }

  public multiply(other: number): ETH {
    // perform floating point multiplication
    // Note: We could take a precision here and do the arithmetic with int
    return new ETH(BigInt(Math.round(BigInt(this.wei).toJSNumber() * other)));
  }

  public divide(other: number): ETH {
    // perform floating point division
    // Note: We could take a precision here and do the arithmetic with int
    return new ETH(BigInt(Math.round(BigInt(this.wei).toJSNumber() / other)));
  }

  public subtract(other: ETH): ETH {
    return new ETH(BigInt(this.wei).subtract(other.wei));
  }

  public add(other: ETH): ETH {
    return new ETH(BigInt(this.wei).plus(other.wei));
  }

  public lt(other: ETH): boolean {
    return this.wei < other.wei;
  }
}

export class USD {
  static zero: USD = new USD(0);

  // TODO: This should probably store as int cents
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
