import 'dart:math' as math;

import 'package:fitpact/core/math/angle_calculator.dart';
import 'package:fitpact/core/math/point_3d.dart';

/// Result of a single push-up form validation.
class FormFeedback {
  /// Overall form score in the range 0.0 - 1.0.
  final double score;

  /// Human-readable coaching message.
  final String message;

  /// Whether required landmarks were missing, making the score partial.
  final bool incomplete;

  /// Creates a feedback result.
  const FormFeedback({
    required this.score,
    required this.message,
    this.incomplete = false,
  });

  /// Feedback used when landmarks needed for validation are missing.
  factory FormFeedback.incomplete(String message) => FormFeedback(
        score: 0,
        message: message,
        incomplete: true,
      );
}

/// Landmarks for one push-up sample, as 3D pose keypoints.
class PushUpLandmarks {
  /// Left shoulder.
  final Point3D? leftShoulder;

  /// Right shoulder.
  final Point3D? rightShoulder;

  /// Left elbow.
  final Point3D? leftElbow;

  /// Right elbow.
  final Point3D? rightElbow;

  /// Left wrist.
  final Point3D? leftWrist;

  /// Right wrist.
  final Point3D? rightWrist;

  /// Left hip.
  final Point3D? leftHip;

  /// Right hip.
  final Point3D? rightHip;

  /// Left knee.
  final Point3D? leftKnee;

  /// Right knee.
  final Point3D? rightKnee;

  /// Creates a landmark set; every field is nullable because detection
  /// may fail to observe some keypoints.
  const PushUpLandmarks({
    this.leftShoulder,
    this.rightShoulder,
    this.leftElbow,
    this.rightElbow,
    this.leftWrist,
    this.rightWrist,
    this.leftHip,
    this.rightHip,
    this.leftKnee,
    this.rightKnee,
  });
}

/// Validates push-up form from pose landmarks.
///
/// Every validator returns a [FormFeedback] with a score between 0.0 and
/// 1.0 plus a coaching message. When the needed landmarks are missing the
/// result is marked [FormFeedback.incomplete].
class PushUpFormValidator {
  /// Maximum allowed deviation (degrees) of the elbow from the target angle.
  static const double elbowTolerance = 15;

  /// Maximum allowed deviation (degrees) from a straight shoulder-hip line.
  static const double alignmentTolerance = 10;

  /// Validates the shoulder (upper-arm to torso) angle.
  FormFeedback validateShoulderAngle(PushUpLandmarks lm) {
    final side = _pickSide(
      lm.leftShoulder, lm.leftElbow, lm.leftHip,
      lm.rightShoulder, lm.rightElbow, lm.rightHip,
    );
    if (side == null) {
      return FormFeedback.incomplete('Shoulder landmarks missing');
    }
    final angle = AngleCalculator.calculate(side.b, side.a, side.c);
    if (AngleCalculator.isWithinThreshold(angle, 45, 30)) {
      return const FormFeedback(score: 1.0, message: 'Shoulder angle good');
    }
    final deviation = (angle - 45) / 45;
    return FormFeedback(
      score: (1 - deviation.abs()).clamp(0.0, 1.0),
      message: 'Adjust shoulder angle (currently ${angle.round()}\u00B0)',
    );
  }

  /// Validates the elbow angle (shoulder-elbow-wrist).
  FormFeedback validateElbowAngle(PushUpLandmarks lm) {
    final side = _pickSide(
      lm.leftShoulder, lm.leftElbow, lm.leftWrist,
      lm.rightShoulder, lm.rightElbow, lm.rightWrist,
    );
    if (side == null) {
      return FormFeedback.incomplete('Elbow landmarks missing');
    }
    final angle = AngleCalculator.calculate(side.a, side.b, side.c);
    if (AngleCalculator.isWithinThreshold(angle, 90, elbowTolerance)) {
      return const FormFeedback(score: 1.0, message: 'Elbow angle good');
    }
    final deviation = (angle - 90) / 90;
    return FormFeedback(
      score: (1 - deviation.abs()).clamp(0.0, 1.0),
      message: 'Adjust elbow angle (currently ${angle.round()}\u00B0)',
    );
  }

  /// Validates that shoulders, hips and knees form a straight line.
  FormFeedback validateBodyAlignment(PushUpLandmarks lm) {
    if (lm.leftShoulder == null ||
        lm.rightShoulder == null ||
        lm.leftHip == null ||
        lm.rightHip == null) {
      return FormFeedback.incomplete('Alignment landmarks missing');
    }
    final shoulder = _midpoint(lm.leftShoulder!, lm.rightShoulder!);
    final hip = _midpoint(lm.leftHip!, lm.rightHip!);

    final line = shoulder + hip.scale(-1);
    if (line.length == 0) {
      return FormFeedback.incomplete('Degenerate alignment');
    }

    // Tilt of the body line: angle between the shoulder-hip segment and the
    // hip-knee segment. Collinear segments (straight body) give 0 degrees.
    var tilt = 0.0;

    if (lm.leftKnee != null && lm.rightKnee != null) {
      final knee = _midpoint(lm.leftKnee!, lm.rightKnee!);
      final kneeLine = knee + hip.scale(-1);
      final denom = kneeLine.length * line.length;
      if (denom > 0) {
        final cosKnee = (kneeLine.dot(line) / denom).clamp(-1.0, 1.0);
                final kneeTilt = math.acos(cosKnee.abs()) * 180 / math.pi;
        if (kneeTilt > tilt) tilt = kneeTilt;
      }
    }

    if (tilt <= alignmentTolerance) {
      return const FormFeedback(score: 1.0, message: 'Body aligned');
    }
    final penalty = ((tilt - alignmentTolerance) / 90).clamp(0.0, 1.0);
    return FormFeedback(
      score: (1 - penalty).clamp(0.0, 1.0),
      message: 'Keep body straight (tilt ${tilt.round()}\u00B0)',
    );
  }

  /// Validates rep depth from the elbow angle at the bottom.
  FormFeedback validateDepth(double bottomElbowAngle) {
    if (bottomElbowAngle < 0 || bottomElbowAngle > 180) {
      return FormFeedback.incomplete('Invalid elbow angle');
    }
    if (bottomElbowAngle <= 90) {
      return const FormFeedback(score: 1.0, message: 'Depth reached');
    }
    final penalty = ((bottomElbowAngle - 90) / 90).clamp(0.0, 1.0);
    return FormFeedback(
      score: (1 - penalty).clamp(0.0, 1.0),
      message: 'Go deeper (elbow at ${bottomElbowAngle.round()}\u00B0)',
    );
  }

  /// Aggregated feedback across all validators.
  FormFeedback validate(PushUpLandmarks lm, {double? bottomElbowAngle}) {
    final results = [
      validateShoulderAngle(lm),
      validateElbowAngle(lm),
      validateBodyAlignment(lm),
      if (bottomElbowAngle != null) validateDepth(bottomElbowAngle),
    ];
    if (results.every((r) => r.incomplete)) {
      return FormFeedback.incomplete('Not enough landmarks to validate');
    }
    final scored = results.where((r) => !r.incomplete).toList();
    final score =
        scored.map((r) => r.score).reduce((a, b) => a + b) / scored.length;
    final worst = scored.reduce((a, b) => a.score <= b.score ? a : b);
    return FormFeedback(score: score, message: worst.message);
  }

  ({Point3D a, Point3D b, Point3D c})? _pickSide(
    Point3D? la, Point3D? lb, Point3D? lc,
    Point3D? ra, Point3D? rb, Point3D? rc,
  ) {
    if (la != null && lb != null && lc != null) {
      return (a: la, b: lb, c: lc);
    }
    if (ra != null && rb != null && rc != null) {
      return (a: ra, b: rb, c: rc);
    }
    return null;
  }

  Point3D _midpoint(Point3D a, Point3D b) => (a + b).scale(0.5);
}