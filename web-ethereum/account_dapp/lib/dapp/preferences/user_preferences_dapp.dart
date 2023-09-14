import 'dart:convert';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_log.dart';
import 'dapp_transaction.dart';

class UserPreferencesDapp {
  static final UserPreferencesDapp _singleton = UserPreferencesDapp._internal();

  factory UserPreferencesDapp() {
    return _singleton;
  }

  UserPreferencesDapp._internal();

  ///
  /// Begin: dapp transactions
  ///

  /// Tracked user dapp transactions
  ObservablePreference<List<DappTransaction>> transactions =
      ObservablePreference(
          key: UserPreferenceKeyDapp.Transactions,
          getValue: (key) {
            return _getTransactions();
          },
          putValue: (key, List<DappTransaction>? txs) {
            return _setTransactions(txs);
          });

  void addTransaction(DappTransaction tx) {
    transactions.set(transactions.get()! + [tx]);
  }

  void addTransactions(Iterable<DappTransaction> txs) {
    transactions.set(transactions.get()! + txs.toList());
  }

  void removeTransaction(String txHash) {
    var list = transactions.get()!;
    list.removeWhere((tx) => tx.transactionHash == txHash);
    transactions.set(list);
  }

  static List<DappTransaction> _getTransactions() {
    String? value =
        UserPreferences().getStringForKey(UserPreferenceKeyDapp.Transactions);
    if (value == null) {
      return [];
    }
    try {
      var jsonList = jsonDecode(value) as List<dynamic>;
      return jsonList.map((el) {
        return DappTransaction.fromJson(el);
      }).toList();
    } catch (err) {
      log("Error retrieving txs!: $err");
      return [];
    }
  }

  static Future<bool> _setTransactions(Iterable<DappTransaction>? txs) async {
    txs ??= [];
    print("XXX setTxs: storing txs: ${jsonEncode(txs.toList())}");
    try {
      var value = jsonEncode(txs.toList());
      return await UserPreferences()
          .putStringForKey(UserPreferenceKeyDapp.Transactions, value);
    } catch (err) {
      log("Error storing txs!: $err");
      return false;
    }
  }

  ///
  /// End: dapp transactions
  ///
}

enum UserPreferenceKeyDapp implements UserPreferenceKey {
  Transactions,
}
