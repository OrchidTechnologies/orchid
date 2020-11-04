import "../i18n/i18n_util"
import React, {EffectCallback, FC, useEffect, useRef} from "react";
import {Row} from "react-bootstrap";
import {isEthAddress} from "../api/orchid-eth";
import {intl} from "../index";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

// Return the relative path of the deployment
export function basePath(): string {
  let pathComponents = new URL(window.location.href).pathname.split('/');
  pathComponents.pop();
  return pathComponents.join('/');
}

export function extraPath(): string | undefined {
  let pathComponents = new URL(window.location.href).pathname.split('/');
  return pathComponents.pop();
}

export function hashPath(): string | undefined {
  return new URL(window.location.href).hash;
}

export function getParam(name: string): string | null {
  let params = new URL(window.location.href).searchParams;
  return params.get(name);
}

export function getBoolParam(name: string, defaultValue: boolean): boolean {
  let val = getParam(name);
  if (val == null) {
    return defaultValue;
  }
  return val.toLocaleLowerCase() === "true";
}

export function isDebug(): boolean {
  return getBoolParam("debug", false);
}

  export function getEthAddressParam(name: string, defaultValue: string): string {
  let addr = getParam(name);

  if (addr == null) {
    return defaultValue;
  }

  // Some servers won't let you put a big hex string in the url
  if (!addr.startsWith("0x")) {
    addr = "0x" + addr;
  }
  if (isEthAddress(addr)) {
    return addr;
  } else {
    console.log("Error: Invalid ETH address: ", addr)
    return defaultValue;
  }
}

export function isNumeric(val: any) {
  if (val == null || val === "") {
    return false;
  }
  return !isNaN(val)
}

// Return the float value or null if not numeric.
export function parseFloatSafe(val: string | null): number | null {
  if (val === null) {
    return null
  }
  return isNumeric(val) ? parseFloat(val) : null;
}

// Return the int value or null if not numeric.
export function parseIntSafe(val: string): number | null {
  let ivalue = parseInt(val);
  return ('' + ivalue === val) ? ivalue : null;
}

// Return the BigInt value or null if not numeric.
export function parseBigIntSafe(val: string): BigInt | null {
  return isNumeric(val) ? BigInt(parseFloat(val)) : null;
}

export function errorClass(val: boolean): string {
  return val ? "error" : "hidden";
}

export function pascalCase(str: string): string {
  return str.replace(/^(.)/, (c) => {
    return c.toUpperCase()
  })
}

export function camelCase(str: string): string {
  return str.replace(/^(.)/, (c) => {
    return c.toLowerCase()
  })
}

export const Divider: FC<{ noGutters?: boolean, marginTop?: number, marginBottom?: number }> = (props) => {
  return <Row
    className={"divider " + (props.noGutters ? "no-gutters" : "")}
    style={{
      height: '1px',
      backgroundColor: 'lightGrey',
      marginTop: props.marginTop,
      marginBottom: props.marginBottom,
    }}/>
};

export const Visibility: FC<{ visible: boolean }> = (props) => {
  return <div className={props.visible ? "" : "hidden"}>{props.children}</div>
};

export function copyTextToClipboard(text: string) {
  // https://stackoverflow.com/questions/49618618/copy-current-url-to-clipboard
  let dummy = document.createElement('input');
  document.body.appendChild(dummy);
  dummy.value = text;
  dummy.select();
  document.execCommand('copy');
  document.body.removeChild(dummy);
}

export function testLocalization_(en: Record<string, any>) {
  let msgs: Record<string, string> = {};
  Object.keys(en).forEach(key => {

    // Mix the case
    let org = en[key];
    if ((typeof org) !== "string") {
      return;
    }
    let mod = "";
    for (let i = 0; i < org.length; i++) {
      let char = (org as string).charAt(i);
      mod += i % 2 === 0 ? char.toUpperCase() : char.toLowerCase();
    }
    msgs[key] = mod;
  });
  return msgs;
}

/// Remove any "0x" prefix on a hex string.
export function removeHexPrefix(value: string | undefined): string | undefined {
  if (!value) {
    return value;
  }
  return value.startsWith('0x') ? value.substr(2) : value;
}

// TODO: Move into number extension in i18 utils?
/// Format a currency to default two digits of precision with an optional suffix
/// and null behavior.
export function formatCurrency(
  value: number, suffix: string, digits: number = 2, ifNull: string = "..."): string {
  if (value == null) {
    return ifNull;
  }
  // TODO: Why can't I call this global interface extension method here as elsewhere?
  //return value.toFixedLocalized(digits) + (suffix != null ? " $suffix" : "");
  return intl.formatNumber(value, {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits
  }) + (suffix != null ? ` ${suffix}` : "");
}

/// Return an hsb color ranging from green to yellow to red for values 0.0 to 1.0;
export function trafficLightShade(value: number) {
    value = 1.0 - Math.min(1.0, value);
    return {h: value * 0.3, s: 0.9, b: 0.9}
}

// https://overreacted.io/making-setinterval-declarative-with-react-hooks/
export function useInterval(callback: EffectCallback, delay: number) {
  const savedCallback = useRef<EffectCallback>();

  // Remember the latest callback.
  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  // Set up the interval.
  useEffect(() => {
    function tick() {
      if (savedCallback.current !== undefined) {
        savedCallback.current();
      }
    }
    if (delay !== null) {
      let id = setInterval(tick, delay);
      return () => clearInterval(id);
    }
  }, [delay]);
}

export interface CancellablePromise<T> {
  promise: Promise<T>
  cancel(): void
}

export function makeCancelable<T>(promise: Promise<T>): CancellablePromise<T> {
  let hasCanceled_ = false;

  const wrappedPromise = new Promise<T>((resolve, reject) => {
    promise.then(
      val => hasCanceled_ ? reject({isCanceled: true}) : resolve(val),
      error => hasCanceled_ ? reject({isCanceled: true}) : reject(error)
    );
  });

  return {
    promise: wrappedPromise,
    cancel() {
      hasCanceled_ = true;
    },
  } as CancellablePromise<T>;
}
