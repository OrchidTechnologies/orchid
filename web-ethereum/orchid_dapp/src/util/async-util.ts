import {useEffect, useRef} from "react";

export interface CancellablePromise<T> {
  promise: Promise<T>

  cancel(): void
}

export interface Cancellable {
  cancel(): void
}

// Make a Promise cancellable by offering a cancel() method that triggers its reject().
export function makeCancellable<T>(
  promise: Promise<T>,
  disposal?: Array<Cancellable>
): CancellablePromise<T> {
  let hasCanceled_ = false;

  const wrappedPromise = new Promise<T>((resolve, reject) => {
    promise.then(
      val => hasCanceled_ ? reject({isCanceled: true}) : resolve(val),
      error => hasCanceled_ ? reject({isCanceled: true}) : reject(error)
    );
  });

  let cancallablePromise = {
    promise: wrappedPromise,
    cancel() {
      hasCanceled_ = true;
    },
  } as CancellablePromise<T>;
  if (disposal) {
    disposal.push(cancallablePromise)
  }
  return cancallablePromise;
}

interface ObjectDict {
  [index: string]: any;
}

// Log property changes for the supplied array of props.
// https://stackoverflow.com/a/51082563/74975
export function useTraceUpdate(props: any) {
  const prev = useRef(props);
  useEffect(() => {
    const changedProps = Object.entries(props).reduce(
      (lookup: ObjectDict, [key, value]) => {
        if (prev.current[key] !== value) {
          lookup[key] = [prev.current[key], value];
        }
        return lookup;
      },
      {}
    );
    if (Object.keys(changedProps).length > 0) {
      console.log("trace changed props:", changedProps);
    }
    prev.current = props;
  });
}

