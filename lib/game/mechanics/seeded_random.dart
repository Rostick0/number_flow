/// Deterministic PRNG (mulberry32) whose whole state is one int.
///
/// `dart:math` Random cannot be serialized, but undo, saved games and the
/// daily challenge all need to reproduce the exact same spawn sequence.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  int get state => _state;

  set state(int value) => _state = value & 0xFFFFFFFF;

  int _next32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Uniform int in `[0, max)`.
  int nextInt(int max) {
    assert(max > 0);
    return _next32() % max;
  }

  /// Uniform double in `[0, 1)`.
  double nextDouble() => _next32() / 0x100000000;

  bool chance(double probability) => nextDouble() < probability;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }
}
