import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/plus_code.dart';

/// The expected values below were produced by Google's reference
/// implementation (`js/src/openlocationcode.js` from
/// https://github.com/google/open-location-code) for the same coordinates and
/// precision, so this test pins our encoder to the published grid rather than
/// to my reading of the specification.
void main() {
  group('PlusCode.encode', () {
    void expectCode({
      required String label,
      required double latitude,
      required double longitude,
      required String tenDigits,
      required String eightDigits,
    }) {
      test('$label -> $tenDigits', () {
        expect(
          PlusCode.encode(latitude, longitude),
          tenDigits,
          reason: '$label at 10 digits',
        );
        expect(
          PlusCode.encode(latitude, longitude, codeLength: 8),
          eightDigits,
          reason: '$label at 8 digits',
        );
      });
    }

    expectCode(
      label: 'Nairobi CBD',
      latitude: -1.286389,
      longitude: 36.817223,
      tenDigits: '6GCRPR78+CV',
      eightDigits: '6GCRPR78+',
    );
    expectCode(
      label: 'Ludwigsburg test pin',
      latitude: 48.86129514,
      longitude: 9.24789206,
      tenDigits: '8FWFV66X+G5',
      eightDigits: '8FWFV66X+',
    );
    expectCode(
      label: 'the Open Location Code documentation example',
      latitude: 51.521251,
      longitude: -0.203586,
      tenDigits: '9C3XGQCW+GH',
      eightDigits: '9C3XGQCW+',
    );
    expectCode(
      label: 'Mombasa',
      latitude: -4.0435,
      longitude: 39.6682,
      tenDigits: '6G7XXM49+J7',
      eightDigits: '6G7XXM49+',
    );
    expectCode(
      label: 'Sydney (southern, eastern)',
      latitude: -33.8688,
      longitude: 151.2093,
      tenDigits: '4RRH46J5+FP',
      eightDigits: '4RRH46J5+',
    );
    expectCode(
      label: 'the origin',
      latitude: 0,
      longitude: 0,
      tenDigits: '6FG22222+22',
      eightDigits: '6FG22222+',
    );
    expectCode(
      label: 'the north-east corner',
      latitude: 89.9,
      longitude: 179.9,
      tenDigits: 'CVXXWW22+22',
      eightDigits: 'CVXXWW22+',
    );
    expectCode(
      label: 'the south-west corner',
      latitude: -89.9,
      longitude: -179.9,
      tenDigits: '22224422+22',
      eightDigits: '22224422+',
    );
  });

  group('PlusCode.encode validation', () {
    test('rejects a latitude outside the globe', () {
      expect(() => PlusCode.encode(90.1, 0), throwsArgumentError);
      expect(() => PlusCode.encode(-90.1, 0), throwsArgumentError);
    });

    test('rejects a longitude outside the globe', () {
      expect(() => PlusCode.encode(0, 180.1), throwsArgumentError);
      expect(() => PlusCode.encode(0, -180.1), throwsArgumentError);
    });

    test('rejects a non-finite coordinate', () {
      expect(() => PlusCode.encode(double.nan, 0), throwsArgumentError);
      expect(() => PlusCode.encode(0, double.nan), throwsArgumentError);
    });

    test('rejects a length it cannot represent', () {
      expect(() => PlusCode.encode(0, 0, codeLength: 1), throwsArgumentError);
      expect(() => PlusCode.encode(0, 0, codeLength: 9), throwsArgumentError);
      expect(() => PlusCode.encode(0, 0, codeLength: 12), throwsArgumentError);
    });

    test('always places the separator after eight characters', () {
      for (final length in [2, 4, 6, 8, 10]) {
        final code = PlusCode.encode(-1.286389, 36.817223, codeLength: length);
        expect(code.indexOf('+'), 8, reason: 'length $length');
      }
    });

    test('pads a low precision code with the reserved character', () {
      // Six digits of precision, padded out to the separator.
      expect(PlusCode.encode(-1.286389, 36.817223, codeLength: 6), '6GCRPR00+');
    });
  });
}
