import 'dart:math' as math;

/// An immutable point (or vector) in 3D space.
class Point3D {
  /// X coordinate.
  final double x;

  /// Y coordinate.
  final double y;

  /// Z coordinate.
  final double z;

  /// The origin point (0, 0, 0).
  const Point3D(this.x, this.y, this.z);

  /// The zero vector, useful for checking edge cases such as normalization.
  static const Point3D zero = Point3D(0, 0, 0);

  /// Euclidean distance between this point and [other].
  double distanceTo(Point3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Angle at this point (the vertex) between the vectors pointing to
  /// [a] and [b], in degrees.
  ///
  /// Returns 0 if either vector has zero length.
  double angleBetween(Point3D a, Point3D b) {
    final va = Point3D(a.x - x, a.y - y, a.z - z);
    final vb = Point3D(b.x - x, b.y - y, b.z - z);
    final denom = va.length * vb.length;
    if (denom == 0) return 0;
    final cosTheta = (va.dot(vb) / denom).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * 180 / math.pi;
  }

  /// Euclidean length (magnitude) of this vector.
  double get length => math.sqrt(x * x + y * y + z * z);

  /// Dot product of this vector and [other].
  double dot(Point3D other) => x * other.x + y * other.y + z * other.z;

  /// Cross product of this vector and [other].
  Point3D cross(Point3D other) => Point3D(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  /// Returns a unit vector in the same direction as this vector.
  ///
  /// Returns the zero vector if this vector has zero length.
  Point3D normalize() {
    final len = length;
    if (len == 0) return Point3D.zero;
    return Point3D(x / len, y / len, z / len);
  }

  /// Returns this vector scaled by [factor].
  Point3D scale(double factor) => Point3D(x * factor, y * factor, z * factor);

  /// Component-wise addition of this vector and [other].
  Point3D operator +(Point3D other) =>
      Point3D(x + other.x, y + other.y, z + other.z);

  @override
  bool operator ==(Object other) =>
      other is Point3D && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Point3D($x, $y, $z)';
}