import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/math/angle_calculator.dart';
import 'package:fitpact/core/math/point_3d.dart';

void main() {
 group('Mathematical verification', () {
 test('equilateral triangle has three 60-degree angles', () {
 final a = const Point3D(0, 0, 0);
 final b = const Point3D(1, 0, 0);
 final c = Point3D(0.5, math.sqrt(3) / 2, 0);
 expect(AngleCalculator.calculate(a, b, c), closeTo(60, 0.0001));
 expect(AngleCalculator.calculate(b, c, a), closeTo(60, 0.0001));
 expect(AngleCalculator.calculate(c, a, b), closeTo(60, 0.0001));
 });

 test('right triangle angles are 90, 45, 45', () {
 final a = const Point3D(0, 0, 0);
 final b = const Point3D(1, 0, 0);
 final c = const Point3D(1, 1, 0);
 expect(AngleCalculator.calculate(a, b, c), closeTo(90, 0.0001));
 expect(AngleCalculator.calculate(b, a, c), closeTo(45, 0.0001));
 expect(AngleCalculator.calculate(a, c, b), closeTo(45, 0.0001));
 });

 test('3D angles outside the XY plane', () {
 // Vertex at origin; vector along X and vector along Y+Z diagonal are orthogonal (dot = 0).
 final angle = AngleCalculator.calculate(
 const Point3D(1, 0, 0),
 const Point3D(0, 0, 0),
 const Point3D(0, 1, 1),
 );
 expect(angle, closeTo(90, 0.0001));
 // (1,0,0) vs (1,1,0) in 3D: known 45-degree angle with nonzero z.
 final angle2 = AngleCalculator.calculate(
 const Point3D(1, 0, 5),
 const Point3D(0, 0, 5),
 const Point3D(1, 1, 5),
 );
 expect(angle2, closeTo(45, 0.0001));
 });

 test('cross product is perpendicular to both operands', () {
 final a = const Point3D(2, 3, 5);
 final b = const Point3D(-1, 4, 2);
 final cross = a.cross(b);
 expect(cross.dot(a), closeTo(0, 0.0001));
 expect(cross.dot(b), closeTo(0, 0.0001));
 });

 test('near-zero vectors are handled safely', () {
 final tiny = const Point3D(1e-12, 0, 0);
 expect(tiny.normalize().length, closeTo(1, 0.0001));
 // Vector to the zero point is opposite to the vector to (1,0,0).
 expect(
 AngleCalculator.calculate(
 Point3D.zero,
 Point3D(1e-15, 0, 0),
 const Point3D(1, 0, 0)),
 180);
 });

 test('very large coordinates', () {
 final a = const Point3D(1e9, 2e9, 3e9);
 final b = const Point3D(1e9, 2e9, 3e9);
 final c = const Point3D(1e9, 2e9, -3e9);
 // b coincides with a: vector b->a is zero, so the angle is 0.
 expect(AngleCalculator.calculate(a, b, c), 0);
 expect(a.distanceTo(b), 0);
 // Orthogonal large vectors still give 90 degrees.
 final p = const Point3D(1e9, 0, 0);
 final q = const Point3D(0, 1e9, 0);
 expect(
 AngleCalculator.calculate(
 p, Point3D.zero, q),
 closeTo(90, 0.0001));
 });

 test('negative coordinates', () {
 final angle = AngleCalculator.calculate(
 const Point3D(-1, -1, 0),
 const Point3D(-2, -1, 0),
 const Point3D(-2, -2, 0),
 );
 expect(angle, closeTo(90, 0.0001));
 });
 });

 group('Performance', () {
 test('1000 AngleCalculator calls complete in < 100 ms', () {
 final sw = Stopwatch()..start();
 for (var i = 0; i < 1000; i++) {
 AngleCalculator.calculate(
 Point3D(i * 0.001, 1, 0),
 const Point3D(0, 0, 0),
 const Point3D(0, 1, 0),
 );
 }
 sw.stop();
 expect(sw.elapsedMilliseconds, lessThan(100));
 });

 test('1000 Point3D operations complete in < 100 ms', () {
 final a = const Point3D(1, 2, 3);
 final b = const Point3D(4, 5, 6);
 final sw = Stopwatch()..start();
 for (var i = 0; i < 1000; i++) {
 a.distanceTo(b);
 a.normalize();
 a.angleBetween(b, Point3D(i * 0.001, 0, 0));
 }
 sw.stop();
 expect(sw.elapsedMilliseconds, lessThan(100));
 });
 });
}