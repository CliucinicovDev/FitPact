import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/math/angle_calculator.dart';
import 'package:fitpact/core/math/point_3d.dart';

void main() {
  group('AngleCalculator.calculate', () {
    test('90 degrees at vertex', () {
      final angle = AngleCalculator.calculate(
        const Point3D(1, 0, 0),
        const Point3D(0, 0, 0),
        const Point3D(0, 1, 0),
      );
      expect(angle, closeTo(90, 0.0001));
    });

    test('45 degrees at vertex', () {
      final angle = AngleCalculator.calculate(
        const Point3D(1, 0, 0),
        const Point3D(0, 0, 0),
        const Point3D(1, 1, 0),
      );
      expect(angle, closeTo(45, 0.0001));
    });

    test('180 degrees for opposite collinear points', () {
      final angle = AngleCalculator.calculate(
        const Point3D(1, 0, 0),
        const Point3D(0, 0, 0),
        const Point3D(-1, 0, 0),
      );
      expect(angle, closeTo(180, 0.0001));
    });

    test('0 degrees for same-direction collinear points', () {
      final angle = AngleCalculator.calculate(
        const Point3D(1, 0, 0),
        const Point3D(0, 0, 0),
        const Point3D(2, 0, 0),
      );
      expect(angle, closeTo(0, 0.0001));
    });

    test('coincident points return 0', () {
      final angle = AngleCalculator.calculate(
        const Point3D(1, 1, 1),
        const Point3D(1, 1, 1),
        const Point3D(2, 2, 2),
      );
      expect(angle, 0);
    });

    test('works with translated coordinates', () {
      // Vertex at (5, 5, 5), same geometry as the 90-degree case.
      final angle = AngleCalculator.calculate(
        const Point3D(6, 5, 5),
        const Point3D(5, 5, 5),
        const Point3D(5, 6, 5),
      );
      expect(angle, closeTo(90, 0.0001));
    });
  });

  group('AngleCalculator.isInRange', () {
    test('inside range', () {
      expect(AngleCalculator.isInRange(90, 80, 100), isTrue);
    });

    test('boundary min is inclusive', () {
      expect(AngleCalculator.isInRange(80, 80, 100), isTrue);
    });

    test('boundary max is inclusive', () {
      expect(AngleCalculator.isInRange(100, 80, 100), isTrue);
    });

    test('below range', () {
      expect(AngleCalculator.isInRange(79, 80, 100), isFalse);
    });

    test('above range', () {
      expect(AngleCalculator.isInRange(101, 80, 100), isFalse);
    });
  });

  group('AngleCalculator.isWithinThreshold', () {
    test('equal to target', () {
      expect(AngleCalculator.isWithinThreshold(90, 90, 5), isTrue);
    });

    test('exactly at threshold is inclusive', () {
      expect(AngleCalculator.isWithinThreshold(95, 90, 5), isTrue);
    });

    test('within threshold', () {
      expect(AngleCalculator.isWithinThreshold(88, 90, 5), isTrue);
    });

    test('outside threshold', () {
      expect(AngleCalculator.isWithinThreshold(96, 90, 5), isFalse);
    });
  });
}