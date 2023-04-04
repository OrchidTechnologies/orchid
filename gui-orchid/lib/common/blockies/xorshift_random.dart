import 'package:fixnum/fixnum.dart';

// Ported from https://github.com/download13/blockies (WTFPL)
class XorShiftRandom {
  List<int> _state = [];

  XorShiftRandom(String seedValue) {
    _seed(seedValue);
  }

  void _seed(String value) {
    final chars = value.codeUnits;
    _state = new List.filled(4, 0, growable: false);
    for (var i = 0; i < chars.length; i++) {
      _state[i % 4] =
          ((Int32(_state[i % 4]) << 5).toInt() - (_state[i % 4])) + chars[i];
    }
  }

  double nextDouble() {
    // based on Java's String.hashCode(), expanded to 4 32bit values
    var t = (Int32(_state[0]) ^ (Int32(_state[0]) << 11)).toInt();
    _state[0] = _state[1];
    _state[1] = _state[2];
    _state[2] = _state[3];
    _state[3] = (Int32(_state[3]) ^
    (Int32(_state[3]) >> 19) ^
    Int32(t) ^
    (Int32(t) >> 8))
        .toInt();
    return _state[3] / (1 << 31);
  }
}
