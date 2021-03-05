import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/util/enums.dart';

void main() {
  group('test utils', () {
    test('enums', () {
      expect(Enums.toStringValue(PacTransactionType.None), equals('None'));
      expect(Enums.fromString(PacTransactionType.values, 'None'), equals(PacTransactionType.None));
      expect(Enums.fromString(PacTransactionType.values, 'none'), equals(PacTransactionType.None));
    });
  });
}
