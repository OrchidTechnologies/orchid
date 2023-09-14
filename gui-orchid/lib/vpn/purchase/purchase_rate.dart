// A PAC purchase
import 'package:orchid/vpn/preferences/user_secure_storage.dart';
import 'orchid_pac.dart';

class Purchase {
  final DateTime date;
  final double usdAmount;

  Purchase(PAC pac)
      : this.date = DateTime.now(),
        this.usdAmount = pac.usdPriceExact.value;

  Purchase.fromJson(Map<String, dynamic> json)
      : date = DateTime.fromMillisecondsSinceEpoch(json['date']),
        usdAmount = json['usdAmount'];

  Map<String, dynamic> toJson() =>
      {'date': date.millisecondsSinceEpoch, 'usdAmount': usdAmount};
}

/// A mutable container for purchase history.
class PurchaseRateHistory {
  List<Purchase> purchases = [];

  PurchaseRateHistory(this.purchases);

  /// Remove entries older than `duration`.
  /// Returns true if entries were removed.
  void removeOlderThan(Duration duration) {
    purchases.removeWhere((p) {
      return p.date.isBefore(DateTime.now().subtract(duration));
    });
  }

  void add(PAC pac) {
    purchases.add(Purchase(pac));
  }

  double sum() {
    return purchases.isNotEmpty
        ? purchases.map((p) => p.usdAmount).reduce((a, b) => a + b)
        : 0;
  }

  Future<void> save() async {
    return UserSecureStorage().setPurchaseRateHistory(this);
  }

  PurchaseRateHistory.fromJson(Map<String, dynamic> json) {
    this.purchases = (json['purchases'] as List<dynamic>)
        .map((el) => Purchase.fromJson(el))
        .toList();
  }

  Map<String, dynamic> toJson() => {'purchases': purchases};
}
