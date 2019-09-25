
class ScalarValue<T extends num> {
  final T value;
  const ScalarValue(this.value);

  String toString() {
    return value.toString();
  }

  String toStringAsFixed(int len) {
    return value.toStringAsFixed(len);
  }

  bool operator ==(o) => o is ScalarValue<T> && o.value == value;
  int get hashCode => value.hashCode;
}

class OXT extends ScalarValue<double> {
  const OXT(double value) : super(value);
}

class USD extends ScalarValue<double> {
  const USD(double value) : super(value);
}

class Months extends ScalarValue<int> {
  const Months(int value) : super(value);
}

