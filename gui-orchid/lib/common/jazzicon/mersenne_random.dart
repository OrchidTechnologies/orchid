import 'package:fixnum/fixnum.dart';

/// An implementation of the Mersenne Twister PRNG.
/// Emulates 32 bit word length with Mersenne prime 2^19937 − 1.
/// https://en.wikipedia.org/wiki/Mersenne_Twister
class MersenneTwisterRandom {
  static const A = 0x9908B0DF;
  static const M = 397;
  static const N = 624;
  static const U = 11;
  static const S = 7;
  static const T = 15;
  static const L = 18;
  static const B = 0x9D2C5680;
  static const C = 0xEFC60000;
  static const F = 1812433253;
  static const HIGH = 0x80000000;
  static const LOW = 0x7fffffff;

  List<int> state = new List.filled(N, 0, growable: false);
  int index;

  MersenneTwisterRandom(int seed) {
    _seed(seed);
  }

  _seed(int value) {
    state[0] = value.toUnsigned(32);
    for (index = 1; index < N; index++) {
      state[index] =
          ((Int32(F) * Int32(state[index - 1] ^ ((state[index - 1]) >> 30))) +
                  index)
              .toInt()
              .toUnsigned(32);
    }
  }

  int nextInt() {
    // twist
    if (index >= N) {
      _twist();
    }

    // extract number
    int y = state[index++];
    y = (y ^ (y >> U));
    y = (y ^ ((y << S) & B));
    y = (y ^ ((y << T) & C));
    y = (y ^ (y >> L));

    return y;
  }

  void _twist() {
    for (int i = 0; i < N; i++) {
      int x = (state[i] & HIGH) + (state[(i + 1) % N] & LOW);
      int xA = x >> 1;
      if (x % 2 != 0) {
        xA = xA ^ A;
      }
      state[i] = state[(i + M) % N] ^ xA;
    }
    index = 0;
  }

  double nextDouble() {
    return nextInt() * (1.0 / 4294967296.0);
  }
}
