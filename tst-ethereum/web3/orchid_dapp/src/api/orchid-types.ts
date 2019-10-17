// import {Dispatch, SetStateAction, useState} from "react";

export type Address = string;

// Helper for RxJS with Typescript
export function isNotNull<T>(a: T | null): a is T {
  return a !== null;
}

/*
export class State<T> {
  public readonly value: T;
  private setter: Dispatch<SetStateAction<T>>;

  set(value: T) {
    this.setter(value);
  }

  constructor(value: T) {
    [this.value, this.setter] = useState<T>(value);
  }
}

export function state<T>(value: T): State<T> {
  return new State(value);
}
*/
