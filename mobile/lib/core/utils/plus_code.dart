/// Open Location Code ("Plus Code") encoding.
///
/// A Plus Code is a short address derived from a latitude and longitude with no
/// service behind it: useful where a street address cannot describe a site
/// precisely, which is much of Kenya, and free of API keys, quotas and network
/// calls.
///
/// The 10-digit form used here (`6GCRPR78+CV`) covers about 13 m by 13 m —
/// finer than the smallest geofence we allow and precise enough to find a gate —
/// and it can be pasted into Google Maps or any Plus Codes app.
///
/// The arithmetic is integer-based, mirroring Google's reference
/// implementation (<https://github.com/google/open-location-code>). Encoding by
/// dividing degrees with floating point drifts at grid boundaries — a point a
/// fraction of a degree from the antimeridian encodes into the wrong cell — and
/// the reference avoids it by scaling latitude and longitude to integers first.
/// `test/plus_code_test.dart` checks these values against the published grid.
class PlusCode {
  const PlusCode._();

  /// The 20 characters of the grid, in order. `0` is reserved for padding and
  /// is never a digit.
  static const String _alphabet = '23456789CFGHJMPQRVWX';
  static const String _padding = '0';
  static const String _separator = '+';

  /// Digits in a code that addresses the finest pair precision (8 before the
  /// separator, 2 after).
  static const int _pairCodeLength = 10;
  static const int _separatorPosition = 8;

  /// The last five digits of the scaled value address the sub-pair grid, which
  /// this encoder drops rather than resolving into grid digits.
  static const int _gridCodeLength = 5;
  static const int _gridRows = 5;
  static const int _gridColumns = 4;

  static const int _latitudeMax = 90;
  static const int _longitudeMax = 180;

  /// Scaling that makes every digit an integer operation: 20^3 pairs, then the
  /// grid rows/columns to the power of [_gridCodeLength].
  static const int _pairPrecision = 8000;
  static const int _finalLatPrecision = _pairPrecision * 3125; // 25,000,000
  static const int _finalLngPrecision = _pairPrecision * 1024; // 8,192,000

  /// Characters in a code generated at the default precision (8 before `+`).
  static const int defaultLength = 10;

  /// Encodes [latitude]/[longitude] as a Plus Code.
  ///
  /// [codeLength] must be even and between 2 and 10. Ten is the default because
  /// it is the most precise form that decodes without a reference location, so
  /// it can be shared as-is. Codes longer than ten digits need the sub-pair grid
  /// and are not produced here.
  static String encode(
    double latitude,
    double longitude, {
    int codeLength = defaultLength,
  }) {
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'must be between -90 and 90',
      );
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be between -180 and 180',
      );
    }
    if (codeLength < 2 || codeLength > _pairCodeLength || codeLength.isOdd) {
      throw ArgumentError.value(
        codeLength,
        'codeLength',
        'must be an even number between 2 and 10',
      );
    }

    return _encodeIntegers(
      _latitudeToInteger(latitude),
      _longitudeToInteger(longitude),
      codeLength,
    );
  }

  /// Latitude scaled so that 0 is the south pole.
  static int _latitudeToInteger(double latitude) {
    var value =
        (latitude * _finalLatPrecision).floor() +
        _latitudeMax * _finalLatPrecision;

    final limit = 2 * _latitudeMax * _finalLatPrecision;
    if (value < 0) {
      value = 0;
    } else if (value >= limit) {
      // The pole itself is nudged inside the grid so the code stays decodable.
      value = limit - 1;
    }
    return value;
  }

  /// Longitude scaled so that 0 is the antimeridian, wrapped on the way in.
  static int _longitudeToInteger(double longitude) {
    var value =
        (longitude * _finalLngPrecision).floor() +
        _longitudeMax * _finalLngPrecision;

    final period = 2 * _longitudeMax * _finalLngPrecision;
    if (value < 0 || value >= period) {
      // Dart's remainder is already non-negative for a negative value.
      value = value % period;
    }
    return value;
  }

  static String _encodeIntegers(
    int latitude,
    int longitude,
    int codeLength,
  ) {
    // Drop the grid portion so what remains indexes the encoded pairs.
    var lat = latitude ~/ _power(_gridRows, _gridCodeLength);
    var lng = longitude ~/ _power(_gridColumns, _gridCodeLength);

    // Index 8 holds the separator, 9 and 10 the pair after it.
    final code = List<String>.filled(_pairCodeLength + 1, '');
    code[_separatorPosition] = _separator;

    code[_separatorPosition + 1] = _alphabet[lat % _alphabet.length];
    code[_separatorPosition + 2] = _alphabet[lng % _alphabet.length];
    lat ~/= _alphabet.length;
    lng ~/= _alphabet.length;

    // The pairs before the separator, least significant first.
    for (var index = _pairCodeLength ~/ 2 + 1; index >= 0; index -= 2) {
      code[index] = _alphabet[lat % _alphabet.length];
      code[index + 1] = _alphabet[lng % _alphabet.length];
      lat ~/= _alphabet.length;
      lng ~/= _alphabet.length;
    }

    if (codeLength >= _separatorPosition) {
      return code.sublist(0, codeLength + 1).join();
    }

    // A shorter code is padded out to the separator, so every code has the same
    // shape and only the digits before the `+` carry precision.
    return code.sublist(0, codeLength).join() +
        _padding * (_separatorPosition - codeLength) +
        _separator;
  }

  static int _power(int base, int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
