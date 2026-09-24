import 'dart:math' as math;

import '../math/point_3d.dart';

/// Rounding and angle-conversion helpers for [double].
extension DoubleRounding on double {
  /// Rounds this value to [decimals] decimal places.
  ///
  /// Example: `3.14159.roundToDecimals(2) == 3.14`.
  double roundToDecimals(int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (this * factor).roundToDouble() / factor;
  }

  /// Converts this angle from degrees to radians.
  double toRadians() => this * math.pi / 180;

  /// Converts this angle from radians to degrees.
  double toDegrees() => this * 180 / math.pi;
}

/// Aggregate helpers for a list of [Point3D] values.
extension Point3DListUtils on List<Point3D> {
  /// Component-wise mean of all points.
  ///
  /// Returns [Point3D.zero] if the list is empty.
  Point3D average() {
    if (isEmpty) return Point3D.zero;
    final sum = reduce((a, b) => Point3D(a.x + b.x, a.y + b.y, a.z + b.z));
    return Point3D(sum.x / length, sum.y / length, sum.z / length);
  }

  /// Center of mass of the points; an alias of [average].
  Point3D centerOfMass() => average();
}