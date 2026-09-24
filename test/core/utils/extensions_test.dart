import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/math/point_3d.dart';
import 'package:fitpact/core/utils/extensions.dart';

void main() {
  group('roundToDecimals', () {
    test('normal case', () {
      expect(3.14159.roundToDecimals(2), 3.14);
      expect(2.675.roundToDecimals(1), 2.7);
    });

    test('trailing zeros are preserved numerically', () {
      // 1.005 rounds to 1.0 with 1 decimal; value equals 1.0.
      expect(1.004.roundToDecimals(2), 1.0);
      expect(2.500.roundToDecimals(2), 2.5);
    });

    test('negative numbers', () {
      expect((-3.14159).roundToDecimals(2), -3.14);
      expect((-2.5).roundToDecimals(0), -3.0); // roundToDouble rounds half away from zero
    });

    test('decimals = 0', () {
      expect(3.7.roundToDecimals(0), 4.0);
      expect(3.2.roundToDecimals(0), 3.0);
      expect(3.0.roundToDecimals(0), 3.0);
    });
  });

  group('toRadians / toDegrees', () {
    test('known values', () {
      expect(180.0.toRadians(), closeTo(math.pi, 1e-12));
      expect(90.0.toRadians(), closeTo(math.pi / 2, 1e-12));
      expect(0.0.toRadians(), 0);
      expect(math.pi.toDegrees(), closeTo(180, 1e-12));
      expect((math.pi / 2).toDegrees(), closeTo(90, 1e-12));
    });

    test('roundtrip', () {
      for (final deg in [0.0, 45.0, 123.456, -78.9, 360.0]) {
        expect(deg.toRadians().toDegrees(), closeTo(deg, 1e-9));
      }
    });
  });

  group('Point3DListUtils', () {
    test('average of several points', () {
      final pts = [
        const Point3D(1, 2, 3),
        const Point3D(3, 4, 5),
        const Point3D(5, 6, 7),
      ];
      final avg = pts.average();
      expect(avg.x, 3);
      expect(avg.y, 4);
      expect(avg.z, 5);
    });

    test('average of empty list is zero', () {
      expect(<Point3D>[].average(), Point3D.zero);
    });

    test('centerOfMass matches average', () {
      final pts = [
        const Point3D(-1, 0, 2),
        const Point3D(1, 4, -2),
        const Point3D(0, -2, 10),
      ];
      expect(pts.centerOfMass(), pts.average());
    });

    test('single-element list returns that point', () {
      const p = Point3D(2.5, -3.5, 7.25);
      expect([p].average(), p);
      expect([p].centerOfMass(), p);
    });
  });
}