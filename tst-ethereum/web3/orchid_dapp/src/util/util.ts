const BigInt = require("big-integer"); // Mobile Safari requires polyfill

/*
export function getURLParams() {
  let result = new URLParams();
  let params = new URLSearchParams(document.location.search);
  result.potAddress = params.get("pot");
  result.amount = params.get("amount");
  return result;
}*/

// Return the relative path of the deployment 
export function deploymentPath(): string {
  let pathComponents = new URL(window.location.href).pathname.split('/');
  pathComponents.pop();
  return pathComponents.join('/');
}

export function isNumeric(val: any) {
  if (val == null || val === "") {
    return false;
  }
  return !isNaN(val)
}

// Return the float value or null if not numeric.
export function parseFloatSafe(val: string): number | null {
  return isNumeric(val) ? parseFloat(val) : null;
}

// Return the BigInt value or null if not numeric.
export function parseBigIntSafe(val: string): BigInt | null {
  return isNumeric(val) ? BigInt(parseFloat(val)) : null;
}

export function errorClass(val: boolean): string {
  return val ? "error" : "hidden";
}


