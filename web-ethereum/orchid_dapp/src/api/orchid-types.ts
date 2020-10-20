
const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export type EthAddress = string;
export type Secret = string;
export type TransactionId = string;

// TODO: Convert This to a real type as with OXT below
export type KEIKI = BigInt

// Helper for RxJS with Typescript
export function isNotNull<T>(a: T | null): a is T {
  return a !== null;
}

export function isDefined<T>(a: T | undefined): a is T {
  return a !== undefined;
}

class ScalarNumberValue {
  value: number;

  constructor(value: number) {
    this.value = value
  }

  // TODO: These should work, allowing us to remove the duplicate implementations in the
  // TODO: subclasses, however TS can't invoke the constructor, e.g.:
  // TODO: "Class constructor GWEI cannot be invoked without 'new'"
  /*
  public multiply(other: number): this {
    return this.constructor(this.value * other);
  }

  public divide(other: number): this {
    return this.constructor(this.value / other);
  }

  public subtract(other: this): this {
    return this.constructor(this.value - other.value);
  }

  public add(other: this): this {
    return this.constructor(this.value + other.value);
  }
   */

  toString(): string {
    return this.value.toString();
  }

  //bool operator ==(o) => o is ScalarValue<T> && o.value == value;
  // int get hashCode => value.hashCode;
}

class ScalarBigIntValue {
  value: BigInt;

  public constructor(value: BigInt) {
    this.value = value
  }
}

export class OXT extends ScalarNumberValue {
  static zero: OXT = OXT.fromNumber(0);

  public multiply(other: number): OXT {
    return new OXT(this.value * other);
  }

  public divide(other: number): OXT {
    return new OXT(this.value / other);
  }

  public subtract(other: OXT): OXT {
    return new OXT(this.value - other.value);
  }

  public add(other: OXT): OXT {
    return new OXT(this.value + other.value);
  }

  public lessThan(other: OXT): boolean {
    return this.value < other.value;
  }

  // TODO: update to KEIKI
  static fromKeiki(keiki: BigInt): OXT {
    // Note: native, not integer division here
    return new OXT(BigInt(keiki) / 1e18);
  }

  static fromNumber(num: number): OXT {
    return new OXT(num);
  }

  public toKeiki(): KEIKI {
    return BigInt(Math.round(this.value) * 1e18);
  }
}

export function min(a: OXT, b: OXT): OXT {
  return new OXT(Math.min(a.value, b.value));
}
export function max(a: OXT, b: OXT): OXT {
  return new OXT(Math.max(a.value, b.value));
}

// TODO: Work in progress migrating from the typedef
export class Keiki extends ScalarBigIntValue {

  public subtract(other: Keiki): Keiki {
    return new Keiki(BigInt(this.value).minus(other.value));
  }

  public add(other: Keiki): Keiki {
    return new Keiki(BigInt(this.value).plus(other.value));
  }

  static fromOXT(oxt: OXT): KEIKI {
    return oxt.toKeiki();
  }

  public toOXT(): OXT {
    return OXT.fromKeiki(this.value);
  }
}

export class ETH extends ScalarNumberValue {
  static zero: ETH = new ETH(0);

  public static fromWei(wei: BigInt) {
    return new ETH(BigInt(wei) / 1e18);
  }
  public lessThan(other: ETH): boolean {
    return this.value < other.value;
  }
}

export class GWEI extends ScalarNumberValue {
  public multiply(other: number): GWEI {
    return new GWEI(this.value * other);
  }

  public divide(other: number): GWEI {
    return new GWEI(this.value / other);
  }

  public subtract(other: GWEI): GWEI {
    return new GWEI(this.value - other.value);
  }

  public add(other: GWEI): GWEI {
    return new GWEI(this.value + other.value);
  }

  public toEth(): ETH {
    return new ETH(this.value / 1e9);
  }

  public toWei(): BigInt {
    return BigInt(Math.round(this.value) * 1e9);
  }

  public static fromWei(wei: number) {
    return new GWEI(wei / 1e9);
  }
  public static fromWeiString(wei: string) {
    return new GWEI(BigInt(wei) / 1e9);
  }
}

export class USD extends ScalarNumberValue {
  public lessThan(other: USD): boolean {
    return this.value < other.value;
  }
}
