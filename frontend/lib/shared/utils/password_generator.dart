import 'dart:math';

class PasswordGenOptions {
  const PasswordGenOptions({
    this.length = 20,
    this.lower = true,
    this.upper = true,
    this.digits = true,
    this.symbols = true,
  });

  final int length;
  final bool lower;
  final bool upper;
  final bool digits;
  final bool symbols;

  PasswordGenOptions copyWith({
    int? length,
    bool? lower,
    bool? upper,
    bool? digits,
    bool? symbols,
  }) => PasswordGenOptions(
    length: length ?? this.length,
    lower: lower ?? this.lower,
    upper: upper ?? this.upper,
    digits: digits ?? this.digits,
    symbols: symbols ?? this.symbols,
  );
}

class PasswordGenerator {
  static final _rng = Random.secure();
  static const _lower = 'abcdefghijkmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const _digits = '23456789';
  static const _symbols = '!@#\$%^&*()-_=+[]{};:,./?';

  static String generate(PasswordGenOptions opts) {
    final pool = StringBuffer();
    if (opts.lower) pool.write(_lower);
    if (opts.upper) pool.write(_upper);
    if (opts.digits) pool.write(_digits);
    if (opts.symbols) pool.write(_symbols);
    final s = pool.toString();
    if (s.isEmpty) return '';
    final required = <String>[
      if (opts.lower) _lower[_rng.nextInt(_lower.length)],
      if (opts.upper) _upper[_rng.nextInt(_upper.length)],
      if (opts.digits) _digits[_rng.nextInt(_digits.length)],
      if (opts.symbols) _symbols[_rng.nextInt(_symbols.length)],
    ];
    final remaining = List<String>.generate(
      (opts.length - required.length).clamp(0, opts.length),
      (_) => s[_rng.nextInt(s.length)],
    );
    final all = [...required, ...remaining]..shuffle(_rng);
    return all.join();
  }

  /// 0..1 quality score (rough): based on length and character class diversity.
  static double strength(String password) {
    if (password.isEmpty) return 0;
    var classes = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) classes++;
    if (RegExp(r'[A-Z]').hasMatch(password)) classes++;
    if (RegExp(r'\d').hasMatch(password)) classes++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) classes++;
    final lengthScore = (password.length / 20).clamp(0.0, 1.0);
    final classScore = classes / 4.0;
    return (lengthScore * 0.7 + classScore * 0.3).clamp(0.0, 1.0);
  }
}
