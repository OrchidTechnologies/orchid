/// Capture console and error output to an element with id `logId` in the page.
/*
export function captureLogsTo(logId) {
  window.orgLog = console.log;
  window.logText = "";
  console.log = function (...args) {
    // args = args.map(arg => {
    //     if (typeof arg == "string" || typeof arg == "number") {
    //         return arg
    //     } else {
    //         return JSON.stringify(arg)
    //     }
    // });
    window.logText += "<span>Log: " + args.join(" ") + "</span><br/>";
    let log = document.getElementById(logId);
    if (log) {
      log.innerHTML = logText;
    }
    orgLog.apply(console, arguments);
  };
  // Capture errors
  window.onerror = function (message, source, lineno, colno, error) {
    if (error) message = error.stack;
    console.log('Error: ' + message + ": " + error);
    console.log('Error json: ', JSON.stringify(error));
  };
  window.onload = function () {
    console.log("Loaded.");
  };
}
 */

/*
export function getURLParams() {
  let result = new URLParams();
  let params = new URLSearchParams(document.location.search);
  result.potAddress = params.get("pot");
  result.amount = params.get("amount");
  return result;
}*/

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


