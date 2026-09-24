import 'dart:math' as math;

import 'point_3d.dart';

/// Utility class for computing joint angles from 3D landmarks.
abstract final class AngleCalculator {
  /// Angle at vertex [b], in degrees, formed by points [a]-[b]-[c].
  ///
  /// Returns 0 for degenerate cases (coincident points / zero-length vectors).
  static double calculate(Point3D a, Point3D b, Point3D c) =>
      b.angleBetween(a, c);

  /// Whether [angle] (degrees) lies within the inclusive range [min]-[max].
  static bool isInRange(double angle, double min, double max) =>
      angle >= min && angle <= max;

  /// Whether [angle] is within [thresholdDegrees] of [target], inclusive.
  static bool isWithinThreshold(double angle, double target, double thresholdDegrees) =>
      (angle - target).abs() <= thresholdDegrees;

  /// Converts [degrees] to radians.
  static double toRadians(double degrees) => degrees * math.pi / 180;

  /// Converts [radians] to degrees.
  static double toDegrees(double radians) => radians * 180 / math.pi;
}