@JS() // sets the context, in this case being `window`
library main; // required library declaration
import 'package:js/js.dart';

typedef Callback<T> = void Function(T arg);

@JS()
class Promise<T> {
  external Promise<T> then(Callback<T> successCallback, [Function errorCallback]);
  external Promise<T> catchIt(Function errorCallback);
}

class OrchidJS {
  static Promise<Account> getAccount() {
    return _getAccount();
  }
  static Promise<List<String>> getAccounts() {
    return _getAccounts();
  }
  static bool isAddress(String str) {
    return _isAddress(str);
  }
  static Promise<bool> fundPot(String addr, int amount) {
    return _fundPot(addr, "$amount");
  }
}

@JS()
class Account {
  String address;
  String ethBalance;
  String oxtBalance;
}

@JS('getAccount')
external Promise<Account> _getAccount();

@JS('getAccounts')
external Promise<List<String>> _getAccounts();

@JS('isAddress')
external bool _isAddress(String str);

@JS('fundPot')
external Promise<bool> _fundPot(String addr, String amount);

