/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module plugin.random;
import core.plugin;

class RandomPlugin : Plugin {
  mixin PluginMixin;

  public {
    override void setup(Config conf) {
      _rand = new MerseneTwisterRandom();
    }

    double uniform() {
      return _rand.uniform();
    }

    T rand(T)(T hi) {
      return cast(T)(uniform() * cast(double)hi);
    }

    T rand(T)(T lo, T hi) {
      return rand!T(hi - lo) + lo;
    }

  }
  private {
    MerseneTwisterRandom _rand;
  }
}

class MerseneTwisterRandom {
  public {
    this() {
      seedgen(Clock.currStdTime);
      next = 0;
    }
    this(ulong seed) {
      seedgen(seed);
      next = 0;
    }

    double uniform() {
      return randgen() * (1.0 / (MAX + 1.0));
    }
  }

  private {
    immutable int N = 624;
    immutable int M = 397;
    immutable ulong MATRIX_A = 0x9908b0dfUL;
    immutable ulong UPPER_MASK = 0x80000000UL;
    immutable ulong LOWER_MASK = 0x7fffffffUL;
    immutable ulong MAX = 0xffffffffUL;

    ulong[N] x;
    int next;

    void seedgen(ulong seed) {
      x[0] = seed & MAX;
      foreach(int i; 1..N) {
        x[i] = (1812433253UL *
                (x[i - 1] ^ (x[i - 1] >> 30)) + i);
        x[i] &= MAX;
      }
    }

    ulong randgen()
    {
      ulong rnd;
      if(next >= N) {
        ulong a;

        foreach(int i; 0..N-1) {
          rnd = (x[i] & UPPER_MASK) | x[i + 1] & LOWER_MASK;
          a = (rnd & 0x1UL) ? MATRIX_A : 0x0UL;
          x[i] = x[(i + M) % N] ^ (rnd >> 1) ^ a;
        }
        rnd = (x[N - 1] & UPPER_MASK) | x[0] & LOWER_MASK;
        a = (rnd & 0x1UL) ? MATRIX_A : 0x0UL;
        x[N - 1] = x[M - 1] ^ (rnd >> 1) ^ a;

        next = 0; // Rewind index
      }

      rnd = x[next++];

      // Voodoo to improve distribution
      rnd ^= (rnd >> 11);
      rnd ^= (rnd << 7) & 0x9d2c5680UL;
      rnd ^= (rnd << 15) & 0xefc60000UL;
      rnd ^= (rnd >> 18);

      return rnd;
    }
  }
}
