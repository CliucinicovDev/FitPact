import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/math/point_3d.dart';

void main() {
  group('Point3D', () {
    test('distanceTo computes Euclidean distance', () {
      final a = Point3D(1, 2, 3);
      final b = Point3D(4, 6, 3);
      expect(a.distanceTo(b), closeTo(5, 1e-9));
    });

    test('dot computes dot product', () {
      final a = Point3D(1, 2, 3);
      final b = Point3D(4, -5, 6);
      expect(a.dot(b), 12); // 4 - 10 + 18
    });

    test('cross computes cross product', () {
      final a = Point3D(1, 0, 0);
      final b = Point3D(0, 1, 0);
      expect(a.cross(b), Point3D(0, 0, 1));
      expect(b.cross(a), Point3D(0, 0, -1));
    });

    test('normalize returns unit vector', () {
      final v = Point3D(3, 4, 0);
      final n = v.normalize();
      expect(n.length, closeTo(1, 1e-9));
      expect(n, Point3D(0.6, 0.8, 0));
    });

    test('normalize of zero vector returns zero vector', () {
      expect(Point3D(0, 0, 0).normalize(), Point3D.zero);
    });

    test('scale multiplies components', () {
      final v = Point3D(1, -2, 3);
      expect(v.scale(2.5), Point3D(2.5, -5, 7.5));
    });

    test('angleBetween returns 90 for perpendicular vectors', () {
      final vertex = Point3D(0, 0, 0);
      final a = Point3D(1, 0, 0);
      final b = Point3D(0, 1, 0);
      expect(vertex.angleBetween(a, b), closeTo(90, 1e-9));
    });

    test('angleBetween returns 0 for collinear points', () {
      final vertex = Point3D(1, 1, 1);
      final a = Point3D(2, 1, 1);
      final b = Point3D(5, 1, 1);
      expect(vertex.angleBetween(a, b), closeTo(0, 1e-9));
    });

    test('angleBetween returns known angle', () {
      final vertex = Point3D(0, 0, 0);
      final a = Point3D(1, 0, 0);
      final b = Point3D(1, 1, 0); // 45 degrees
      expect(vertex.angleBetween(a, b), closeTo(45, 1e-9));
    });

    test('operator + adds component-wise', () {
      expect(Point3D(1, 2, 3) + Point3D(4, 5, 6), Point3D(5, 7, 9));
    });
  });
}