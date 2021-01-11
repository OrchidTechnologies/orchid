import {parseFloatSafe} from "../util/util";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

// TokenType describes the ERC20 parameters of the token and serves as a factory for instances of
// the specified token instance type.
export class TokenType<InstanceType extends Token<InstanceType>> {
  chainId: number
  name: string
  symbol: string
  decimals: number

  // Return 1eN where N is the decimal count.
  get multiplier(): number {
    return Math.pow(10, this.decimals);
  }

  constructor(chainId: number, name: string, symbol: string, decimals: number) {
    this.chainId = chainId;
    this.name = name;
    this.symbol = symbol;
    this.decimals = decimals;
  }

  new(intValue: BigInt): InstanceType {
    return new Token(this, intValue) as InstanceType;
  }

  get zero(): InstanceType {
    return this.new(BigInt.zero);
  }

  // From the integer denomination value e.g. WEI for ETH
  fromInt(intValue: BigInt): InstanceType {
    return this.new(intValue);
  }

  // From the integer denomination value e.g. WEI for ETH
  // fromIntOrDefault(intValue: BigInt | undefined, defaultValue: InstanceType): InstanceType {
  //   return intValue ? this.fromInt(intValue) : defaultValue
  // }

  // From a number representing the nominal token denomination, e.g. 1.0 OXT
  fromNumber(val: number): InstanceType {
    return this.new(BigInt(Math.round(val * this.multiplier))); // multiply prior to int conversion
  }

  // From a string representing a number in the nominal token denomination. e.g. "1.0" OXT.
  // Returns null if the string cannot be parsed.
  fromString(val: string | null): InstanceType | null {
    if (val === null) { return null; }
    let floatValue = parseFloatSafe(val);
    if (floatValue === null) {
      return null;
    }
    return this.fromNumber(floatValue);
  }

  // From a string representing the integer denomination. e.g. "1000000000" WEI
  // Throws an error if the value cannot be parsed.
  fromIntString(val: string): InstanceType {
    return this.new(BigInt(val));
  }

  public toString(): string {
    return `${this.chainId}, ${this.name}, ${this.symbol}, ${this.decimals}`
  }
}

// An instance of the ERC20 token type representing a value
// Token is parameterized on a subtype allowing the parent type factory to return specific instance types.
export class Token<T extends Token<T>> {
  type: TokenType<T>;

  // The smallest integer units (e.g. WEI for ETH)
  intValue: BigInt;

  constructor(type: TokenType<T>, intValue: BigInt) {
    this.type = type;
    this.intValue = intValue;
  }

  new(intValue: BigInt): this {
    return new Token(this.type, intValue) as this; // Note the cast
  }

// The float value in nominal units (e.g. ETH, OXT)
  get floatValue(): number {
    return BigInt(this.intValue).toJSNumber() / this.type.multiplier;
  }

  public multiply(other: number): this {
    // perform floating point multiplication
    // Note: We could take a precision here and do the arithmetic with int
    return this.new(BigInt(Math.round(BigInt(this.intValue).toJSNumber() * other)));
  }

  public divide(other: number): this {
    // perform floating point division
    // Note: We could take a precision here and do the arithmetic with int
    return this.new(BigInt(Math.round(BigInt(this.intValue).toJSNumber() / other)));
  }

  public add(other: this): this {
    this.assertType(other)
    return this.new(BigInt(this.intValue).add(other.intValue));
  }

  public subtract(other: this): this {
    this.assertType(other)
    return this.new(BigInt(this.intValue).subtract(other.intValue));
  }

  public eq(other: this): boolean {
    this.assertType(other)
    return BigInt(this.intValue).eq(other.intValue);
  }

  public lt(other: this): boolean {
    this.assertType(other)
    return BigInt(this.intValue).lt(other.intValue);
  }

  public lte(other: this): boolean {
    this.assertType(other)
    return BigInt(this.intValue).leq(other.intValue);
  }

  public gt(other: this): boolean {
    this.assertType(other)
    return BigInt(this.intValue).gt(other.intValue);
  }

  public gte(other: this): boolean {
    this.assertType(other)
    return BigInt(this.intValue).geq(other.intValue);
  }

  public isZero(): boolean {
    return BigInt(this.intValue).eq(BigInt.zero)
  }
  public lteZero(): boolean {
    return BigInt(this.intValue).leq(BigInt.zero)
  }
  public gtZero(): boolean {
    return BigInt(this.intValue).gt(BigInt.zero)
  }

  private assertType(other: this) {
    assertSameType(this, other);
  }

  public toFixedLocalized(decimals: number = 4) {
    decimals = Math.round(decimals);
    return this.floatValue.toFixedLocalized(decimals);
  }

  // Format as currency with the symbol suffixed
  public formatCurrency(digits: number = 4): string {
    return this.toFixedLocalized(digits) + ` ${this.type.symbol}`;
  }

  public toString(): string {
    return `${this.type}, ${this.intValue}`
  }
}

export function assertSameType<T extends Token<T>>(a: Token<T>, b: Token<T>) {
  if (a.type.symbol !== b.type.symbol) {
    throw Error(`Token type mismatch!: ${a.type}, ${b.type}`);
  }
}

export function min<T extends Token<T>>(a: T, b: T): T {
  return BigInt(a.intValue).lt(BigInt(b.intValue)) ? a : b;
}

export function max<T extends Token<T>>(a: T, b: T): T {
  return BigInt(a.intValue).gt(BigInt(b.intValue)) ? a : b;
}

// A meta-type for the lottery token used on the selected chain.
export class LotFunds extends Token<LotFunds> {
  _lotFundsIsUnique: any // Defeat structural subtyping making this class incompatible with GasFunds.
}

// A meta-type for the gas token used on the selected chain.
export class GasFunds extends Token<GasFunds> {
  _gasFundsIsUnique: any // Defeat structural subtyping making this class incompatible with LotFunds.
}

// A stand-in for display purposes in the disconnected state.
export class NoToken extends Token<NoToken> {
  static token: NoToken = new NoToken(new TokenType<NoToken>(0, "No Chain", "Funds", 18), BigInt(0));
}
