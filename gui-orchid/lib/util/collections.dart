// Usage:
// import 'package:orchid/util/collections.dart';

Iterable<E> mapIndexed<E, T>(
    Iterable<T> items, E Function(int index, T item) f) sync* {
  var index = 0;

  for (final item in items) {
    yield f(index, item);
    index = index + 1;
  }
}

extension ExtendedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }

  void forEachIndexed(void Function(E e, int i) f) {
    var i = 0;
    forEach((e) => f(e, i++));
  }
}

extension IterableToMap<K, V, E> on Iterable<E> {
  Map<K, V> toMap<K, V>({
    required K Function(E e) withKey,
    required V Function(E e) withValue,
  }) {
    return {for (var e in this) withKey(e): withValue(e)};
  }
}
