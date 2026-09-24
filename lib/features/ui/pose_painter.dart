import 'dart:math' as math;

import 'package:fitpact/core/math/point_3d.dart';
import 'package:flutter/material.dart';

/// A joint angle label rendered by [PosePainter].
class AngleLabel {
 /// Joint position in image coordinates.
 final Offset position;

 /// Angle value in degrees.
 final double angle;

 /// Whether the joint highlights a form problem.
 final bool hasProblem;

 /// Creates an angle label.
 const AngleLabel({
 required this.position,
 required this.angle,
 this.hasProblem = false,
 });
}

/// Draws a skeleton over detected pose landmarks with bone connections,
/// joint angle labels and a feedback text.
///
/// Bones and joints are green when form is good, red when [hasProblem] is
/// flagged on any label.
class PosePainter extends CustomPainter {
 /// Landmark points in image coordinates.
 final List<Offset> points;

 /// Angle labels displayed at joints.
 final List<AngleLabel> labels;

 /// Coaching feedback text drawn at the top.
 final String feedbackText;

 /// Whether the overall form has a problem (colors everything red).
 final bool hasProblem;

 /// Connections between landmark indices (skeleton bones).
 static const List<List<int>> _bones = [
 [0, 1], [1, 2], [2, 3], [3, 7], // face
 [4, 5], [5, 6], [6, 8],
 [9, 10], // shoulders
 [11, 12], [11, 13], [13, 15], [15, 17], [15, 19], [15, 21], [17, 19], // arms
 [12, 14], [14, 16], [16, 18], [16, 20], [16, 22], [18, 20], // arms
 [11, 23], [12, 24], // torso
 [23, 24], [23, 25], [25, 27], [27, 29], [27, 31], [29, 31], // legs
 [24, 26], [26, 28], [28, 30], [28, 32], [30, 32], // legs
 ];

 /// Creates a painter for one pose frame.
 PosePainter({
 required this.points,
 this.labels = const [],
 this.feedbackText = '',
 this.hasProblem = false,
 });

 @override
 void paint(Canvas canvas, Size size) {
 if (points.isEmpty) return;
 final boneColor = hasProblem ? Colors.red : Colors.green;
 final bonePaint = Paint()
 ..color = boneColor
 ..strokeWidth = 4
 ..strokeCap = StrokeCap.round
 ..style = PaintingStyle.stroke;

 // Bones.
 for (final bone in _bones) {
 final a = _at(bone[0]);
 final b = _at(bone[1]);
 if (a == null || b == null) continue;
 canvas.drawLine(a, b, bonePaint);
 }

 // Joints.
 final jointPaint = Paint()
 ..color = hasProblem ? Colors.red : Colors.green
 ..style = PaintingStyle.fill;
 for (final p in points) {
 canvas.drawCircle(p, 6, jointPaint);
 }

 // Angle labels near joints.
 for (final label in labels) {
 final tp = TextPainter(
 text: TextSpan(
 text: '${label.angle.round()}\u00B0',
 style: TextStyle(
 color: label.hasProblem ? Colors.red : Colors.white,
 fontSize: 14,
 fontWeight: FontWeight.bold,
 ),
 ),
 textDirection: TextDirection.ltr,
 )..layout();
 tp.paint(canvas, label.position + const Offset(10, -20));
 }

 // Feedback text.
 if (feedbackText.isNotEmpty) {
 final tp = TextPainter(
 text: TextSpan(
 text: feedbackText,
 style: TextStyle(
 color: hasProblem ? Colors.red : Colors.green,
 fontSize: 18,
 fontWeight: FontWeight.w600,
 ),
 ),
 textDirection: TextDirection.ltr,
 )..layout(maxWidth: size.width - 32);
 tp.paint(canvas, Offset(16, 16));
 }
 }

 Offset? _at(int index) =>
 index >= 0 && index < points.length ? points[index] : null;

 @override
 bool shouldRepaint(covariant PosePainter old) =>
 old.points != points ||
 old.labels != labels ||
 old.feedbackText != feedbackText ||
 old.hasProblem != hasProblem;
}

/// Utility converting landmark [Point3D] lists to painter points.
abstract final class PosePainterUtils {
 /// Projects [landmarks] (image coordinates) to painter offsets.
 static List<Offset> toOffsets(List<Point3D> landmarks) =>
 [for (final p in landmarks) Offset(p.x, p.y)];

 /// Builds angle labels for the given joint angles (in landmark index
 /// terms) using a [landmarks] list.
 static List<AngleLabel> jointLabels(
 List<Point3D> landmarks,
 List<({int a, int b, int c, double angle, bool problem})> joints,
 ) {
 final labels = <AngleLabel>[];
 for (final j in joints) {
 if (j.b < 0 || j.b >= landmarks.length) continue;
 final vertex = landmarks[j.b];
 labels.add(AngleLabel(
 position: Offset(vertex.x, vertex.y),
 angle: j.angle,
 hasProblem: j.problem,
 ));
 }
 return labels;
 }

 /// Utility for external math users.
 static double deg(double rad) => rad * 180 / math.pi;
}