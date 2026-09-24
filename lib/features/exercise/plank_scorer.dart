import 'dart:math' as math;

/// Scores a completed plank hold.
///
/// The score (0.0 - 1.0) blends three weighted factors:
/// - duration of the hold (weight 0.5)
/// - average body alignment (weight 0.3)
/// - stability, i.e. inverse of the standard deviation of the body
///   angle samples (weight 0.2)
/// A hold shorter than 5 seconds always scores 0.
class PlankScorer {
 /// Minimum hold duration (seconds) for a non-zero score.
 static const double minSeconds = 5;

 /// Duration at which the duration factor maxes out.
 static const double fullSeconds = 60;

 /// Weight of the duration factor.
 static const double durationWeight = 0.5;

 /// Weight of the alignment factor.
 static const double alignmentWeight = 0.3;

 /// Weight of the stability factor.
 static const double stabilityWeight = 0.2;

 /// Maximum deviation (degrees) of the body angle from 180 considered
 /// perfectly aligned.
 static const double alignmentTolerance = 10;

 /// Computes the overall plank score.
 ///
 /// [holdSeconds] is the hold duration in seconds and [bodyAngles] are the
 /// sampled shoulder-hip-knee angles (degrees) during the hold.
 double score(double holdSeconds, List<double> bodyAngles) {
 if (holdSeconds < minSeconds) return 0;

 final durationFactor = ((holdSeconds - minSeconds) / (fullSeconds - minSeconds))
 .clamp(0.0, 1.0);

 final alignmentFactor =
 bodyAngles.isEmpty ? 0.5 : _alignmentFactor(bodyAngles);

 final stabilityFactor =
 bodyAngles.length < 2 ? 0.5 : _stabilityFactor(bodyAngles);

 return (durationWeight * durationFactor +
 alignmentWeight * alignmentFactor +
 stabilityWeight * stabilityFactor)
 .clamp(0.0, 1.0);
 }

 /// Alignment factor: 1.0 when every sample is straight (within
 /// [alignmentTolerance] of 180), decaying linearly to 0 at 90 off.
 double _alignmentFactor(List<double> angles) {
 var sum = 0.0;
 for (final a in angles) {
 final deviation = (180 - a).abs();
 if (deviation <= alignmentTolerance) {
 sum += 1;
 } else {
 sum += (1 - ((deviation - alignmentTolerance) / 90)).clamp(0.0, 1.0);
 }
 }
 return sum / angles.length;
 }

 /// Stability factor: 1.0 when the standard deviation is 0, decaying
 /// linearly to 0 at 20 degrees of deviation.
 double _stabilityFactor(List<double> angles) {
 final mean = angles.reduce((a, b) => a + b) / angles.length;
 var variance = 0.0;
 for (final a in angles) {
 final d = a - mean;
 variance += d * d;
 }
 final std = math.sqrt(variance / angles.length);
 return (1 - std / 20).clamp(0.0, 1.0);
 }
}