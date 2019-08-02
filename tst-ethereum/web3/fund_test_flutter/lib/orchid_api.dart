@JS() // sets the context, in this case being `window`
library main; // required library declaration

import 'package:js/js.dart';

typedef Callback<T> = void Function(T arg);

@JS()
class Promise<T> {
  external Promise<T> then(Callback<T> successCallback, [Function errorCallback]);
}

// Wrap the JS Promise and interpose `allowInterop` on the callbacks.
class JSPromise<T> {
  Promise<T> promise;

  JSPromise(this.promise);

  JSPromise<T> then(Callback<T> successCallback, [Function errorCallback]) {
    promise.then(allowInterop(successCallback), errorCallback != null ? allowInterop(errorCallback) : null);
    return this;
  }
}

@JS()
// Note: Account balances are passed as strings because there is no shared BigInt
// Note: representation between JS and Dart.
class Account {
  String address;
  String ethBalance; // in wei
  String oxtBalance; // in Oxt-wei
}

class OrchidAPI {
  static JSPromise<Account> getAccount() {
    return JSPromise(_getAccount());
  }
  static bool isAddress(String str) {
    return _isAddress(str);
  }
  static JSPromise<String> fundPot(String addr, String amount) {
    return JSPromise(_fundPot(addr, amount));
  }
  static JSPromise<void> debug() {
    return JSPromise(_debug());
  }
  static URLParams getURLParams() {
      return _getURLParams();
  }
  // Get the pot balance in OXT-wei
  static JSPromise<String> getPotBalance(addr) {
    return JSPromise(_getPotBalance(addr));
  }
}

@JS('getAccount')
external Promise<Account> _getAccount();

@JS('isAddress')
external bool _isAddress(String str);

@JS('fundPot')
external Promise<String> _fundPot(String addr, String amount);

@JS('debug')
external Promise<void> _debug();

@JS()
class URLParams {
  String potAddress= "";
  double amount = 0;
}

@JS('getURLParams')
external URLParams _getURLParams();

@JS('getPotBalance')
external Promise<String> _getPotBalance(addr);

