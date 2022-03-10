library mersenne;

import 'package:orchid/api/orchid_log_api.dart';

// Ported from: https://github.com/damoti/mersenne
// Ported to Dart from https://github.com/ottypes/fuzzer/blob/master/lib/mersenne.js by dmitryuv
//
// copied from the npm module 'mersenne', may 2011
//
// this program is a JavaScript version of Mersenne Twister, with concealment and encapsulation in class,
// an almost straight conversion from the original program, mt19937ar.c,
// translated by y. okada on July 17, 2006.
// and modified a little at july 20, 2006, but there are not any substantial differences.
// in this program, procedure descriptions and comments of original source code were not removed.
// lines commented with //c// were originally descriptions of c procedure. and a few following lines are appropriate JavaScript descriptions.
// lines commented with /* and */ are original comments.
// lines commented with // are additional comments in this JavaScript version.
// before using this version, create at least one instance of MersenneTwister19937 class, and initialize the each state, given below in c comments, of all the instances.
/*
   A C-program for MT19937, with initialization improved 2002/1/26.
   Coded by Takuji Nishimura and Makoto Matsumoto.
   Before using, initialize the state by using init_genrand(seed)
   or init_by_array(init_key, key_length).
   Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:
     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.
   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   Any feedback is very welcome.
   http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
   email: m-mat @ math.sci.hiroshima-u.ac.jp (remove space)
*/
class MersenneTwister19937 {
  /* Period parameters */
  //c//#define N 624
  //c//#define M 397
  //c//#define MATRIX_A 0x9908b0dfUL   /* constant vector a */
  //c//#define UPPER_MASK 0x80000000UL /* most significant w-r bits */
  //c//#define LOWER_MASK 0x7fffffffUL /* least significant r bits */
  static const int N = 624;
  static const int M = 397;
  static const MATRIX_A = 0x9908b0df;

  /* constant vector a */
  static const UPPER_MASK = 0x80000000;

  /* most significant w-r bits */
  static const LOWER_MASK = 0x7fffffff;

  /* least significant r bits */

  //c//static unsigned long mt[N]; /* the array for the state vector  */
  //c//static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */
  List<int> mt = new List.filled(N, 0, growable: false);

  /* the array for the state vector  */
  var mti = N + 1;

  /* mti==N+1 means mt[N] is not initialized */

  int _unsigned32(int n1) {
    // returns a 32-bits unsiged integer from an operand to which applied a bit operator.
    // return n1 < 0 ? (n1 ^ UPPER_MASK) + UPPER_MASK : n1;
    return n1.toUnsigned(32);
  }

  // int _subtraction32(int n1, int n2) {
  //   // emulates lowerflow of a c 32-bits unsiged integer variable, instead of the operator -.
  //   // these both arguments must be non-negative integers expressible using unsigned 32 bits.
  //   return n1 < n2
  //       ? _unsigned32((0x100000000 - (n2 - n1)) & 0xffffffff)
  //       : n1 - n2;
  // }

  int _addition32(int n1, int n2) {
    // emulates overflow of a c 32-bits unsiged integer variable, instead of the operator +.
    // these both arguments must be non-negative integers expressible using unsigned 32 bits.
    return _unsigned32((n1 + n2) & 0xffffffff);
  }

  int _multiplication32(int n1, int n2) {
    // In Dart on Web ints are implemented on top of JS native type floating point
    // with only 53 bits of precision. We will emulate what the JS Mersenne impl does here
    // for consistency with it.
    assert(n1 < 4294967296);
    assert(n2 < 4294967296);
    return (((_unsigned32((n1 & 0xffff0000) >> 16) * n2) << 16) + (n1 & 0x0000ffff) * n2);

    // emulates overflow of a c 32-bits unsiged integer variable, instead of the operator *.
    // these both arguments must be non-negative integers expressible using unsigned 32 bits.
    // var sum = 0;
    // for (int i = 0; i < 32; ++i) {
    //   if (((n1 >> i) & 0x1) == 0) {
    //     sum = _addition32(sum, _unsigned32(n2 << i));
    //   }
    // }
    // return sum;
  }

  /* initializes mt[N] with a seed */
  //c//void init_genrand(unsigned long s)
  init_genrand(int s) {
    //c//mt[0]= s & 0xffffffff;
    mt[0] = _unsigned32(s & 0xffffffff);
    for (mti = 1; mti < N; mti++) {
      mt[mti] = //c//(1812433253 * (mt[mti-1] ^ (mt[mti-1] >> 30)) + mti);
          _addition32(
              _multiplication32(
                1812433253,
                _unsigned32(mt[mti - 1] ^ ((mt[mti - 1]) >> 30)),
              ),
              mti);
      /* See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. */
      /* In the previous versions, MSBs of the seed affect   */
      /* only MSBs of the array mt[].                        */
      /* 2002/01/09 modified by Makoto Matsumoto             */
      //c//mt[mti] &= 0xffffffff;
      mt[mti] = _unsigned32(mt[mti] & 0xffffffff);
      /* for >32 bit machines */
    }
  }

  /* initialize by an array with array-length */
  /* init_key is the array for initializing keys */
  /* key_length is its length */
  /* slight change for C++, 2004/2/26 */
  //c//void init_by_array(unsigned long init_key[], int key_length)
  // init_by_array(List<int> init_key, int key_length) {
  //   //c//int i, j, k;
  //   var i, j, k;
  //   //c//init_genrand(19650218);
  //   init_genrand(19650218);
  //   i = 1;
  //   j = 0;
  //   k = (N > key_length ? N : key_length);
  //   for (; k != 0; k--) {
  //     //c//mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1664525))
  //     //c// + init_key[j] + j; /* non linear */
  //     mt[i] = _addition32(
  //         _addition32(
  //             _unsigned32(mt[i] ^
  //                 _multiplication32(
  //                     _unsigned32(mt[i - 1] ^ (mt[i - 1] >> 30)), 1664525)),
  //             init_key[j]),
  //         j);
  //     mt[i] =
  //         //c//mt[i] &= 0xffffffff; /* for WORDSIZE > 32 machines */
  //         _unsigned32(mt[i] & 0xffffffff);
  //     i++;
  //     j++;
  //     if (i >= N) {
  //       mt[0] = mt[N - 1];
  //       i = 1;
  //     }
  //     if (j >= key_length) j = 0;
  //   }
  //   for (k = N - 1; k != 0; k--) {
  //     //c//mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1566083941))
  //     //c//- i; /* non linear */
  //     mt[i] = _subtraction32(
  //         _unsigned32((mt[i]) ^
  //             _multiplication32(
  //                 _unsigned32(mt[i - 1] ^ (mt[i - 1] >> 30)), 1566083941)),
  //         i);
  //     //c//mt[i] &= 0xffffffff; /* for WORDSIZE > 32 machines */
  //     mt[i] = _unsigned32(mt[i] & 0xffffffff);
  //     i++;
  //     if (i >= N) {
  //       mt[0] = mt[N - 1];
  //       i = 1;
  //     }
  //   }
  //   mt[0] = 0x80000000; /* MSB is 1; assuring non-zero initial array */
  // }

  /* moved outside of genrand_int32() by jwatte 2010-11-17; generate less garbage */
  var mag01 = [0x0, MATRIX_A];

  /* generates a random number on [0,0xffffffff]-interval */
  //c//unsigned long genrand_int32(void)
  int genrand_int32() {
    //c//unsigned long y;
    //c//static unsigned long mag01[2]={0x0UL, MATRIX_A};
    var y;
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) {
      /* generate N words at one time */
      //c//int kk;
      var kk;

      if (mti == N + 1) /* if init_genrand() has not been called, */
        //c//init_genrand(5489); /* a default initial seed is used */
        init_genrand(5489);
      /* a default initial seed is used */

      for (kk = 0; kk < N - M; kk++) {
        //c//y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
        //c//mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
        y = _unsigned32((mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK));
        mt[kk] = _unsigned32(mt[kk + M] ^ (y >> 1) ^ mag01[y & 0x1]);
      }
      for (; kk < N - 1; kk++) {
        //c//y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
        //c//mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
        y = _unsigned32((mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK));
        mt[kk] = _unsigned32(mt[kk + (M - N)] ^ (y >> 1) ^ mag01[y & 0x1]);
      }
      //c//y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
      //c//mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
      y = _unsigned32((mt[N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK));
      mt[N - 1] = _unsigned32(mt[M - 1] ^ (y >> 1) ^ mag01[y & 0x1]);
      mti = 0;
    }

    y = mt[mti++];

    /* Tempering */
    //c//y ^= (y >> 11);
    //c//y ^= (y << 7) & 0x9d2c5680;
    //c//y ^= (y << 15) & 0xefc60000;
    //c//y ^= (y >> 18);
    y = _unsigned32(y ^ (y >> 11));
    y = _unsigned32(y ^ ((y << 7) & 0x9d2c5680));
    y = _unsigned32(y ^ ((y << 15) & 0xefc60000));
    y = _unsigned32(y ^ (y >> 18));

    return y;
  }

  // /* generates a random number on [0,0x7fffffff]-interval */
  // //c//long genrand_int31(void)
  // int genrand_int31() {
  //   //c//return (genrand_int32()>>1);
  //   return (genrand_int32() >> 1);
  // }

  // /* generates a random number on [0,1]-real-interval */
  // //c//double genrand_real1(void)
  // double genrand_real1() {
  //   //c//return genrand_int32()*(1.0/4294967295.0);
  //   return genrand_int32() * (1.0 / 4294967295.0);
  //   /* divided by 2^32-1 */
  // }
  //
  // /* generates a random number on [0,1)-real-interval */
  // //c//double genrand_real2(void)
  // double genrand_real2() {
  //   //c//return genrand_int32()*(1.0/4294967296.0);
  //   return genrand_int32() * (1.0 / 4294967296.0);
  //   /* divided by 2^32 */
  // }
  //
  // /* generates a random number on (0,1)-real-interval */
  // //c//double genrand_real3(void)
  // double genrand_real3() {
  //   //c//return ((genrand_int32()) + 0.5)*(1.0/4294967296.0);
  //   return ((genrand_int32()) + 0.5) * (1.0 / 4294967296.0);
  //   /* divided by 2^32 */
  // }

  // /* generates a random number on [0,1) with 53-bit resolution*/
  // //c//double genrand_res53(void)
  // double genrand_res53() {
  //   //c//unsigned long a=genrand_int32()>>5, b=genrand_int32()>>6;
  //   var a = genrand_int32() >> 5, b = genrand_int32() >> 6;
  //   return (a * 67108864.0 + b) * (1.0 / 9007199254740992.0);
  // }
  /* These real versions are due to Isaku Wada, 2002/01/09 added */
}

class MersenneTwister {
  final MersenneTwister19937 _generator;

  MersenneTwister(int seed) : this._generator = new MersenneTwister19937() {
    _generator.init_genrand(seed);
  }

  double nextDouble() {
    return nextInt() * (1.0 / 4294967296.0);
  }

  int nextInt() {
    return _generator.genrand_int32();
  }
}
