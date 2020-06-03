const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export type Address = string;
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

class ScalarValue {
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

export class OXT extends ScalarValue {

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

  static fromKeiki(keiki: BigInt): OXT {
    // Note: native, not integer division here
    return new OXT(BigInt(keiki) / 1e18);
  }

  public toKeiki(): KEIKI {
    return BigInt(this.value * 1e18);
  }
}

export function min(a: OXT, b: OXT): OXT {
  return new OXT(Math.min(a.value, b.value));
}

export class ETH extends ScalarValue {
}

export class GWEI extends ScalarValue {
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
    return BigInt(this.value * 1e9);
  }

  public static fromWei(wei: number) {
    return new GWEI(wei / 1e9);
  }
}

export class USD extends ScalarValue {
}
