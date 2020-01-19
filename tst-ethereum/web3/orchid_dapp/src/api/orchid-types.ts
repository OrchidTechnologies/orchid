
export type Address = string;
export type Secret = string;
export type TransactionId = string;

// Helper for RxJS with Typescript
export function isNotNull<T>(a: T | null): a is T {
  return a !== null;
}
export function isDefined<T>(a: T | undefined): a is T {
  return a !== undefined;
}


