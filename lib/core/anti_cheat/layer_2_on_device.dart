import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';
import 'package:fitpact/core/proof/proof_generator.dart';

/// Layer 2 on-device checks: minimum rep duration, full angle range and
/// landmark variance across the rep's frames.
class Layer2OnDevice {
 /// Minimum ms for a plausible rep.
 final int minRepDurationMs;
 /// Minimum angle range (degrees) across frames.
 final double minAngleRangeDeg;
 /// Minimum variance of a tracked landmark across frames.
 final double minVariance;

 const Layer2OnDevice({
 this.minRepDurationMs = 500,
 this.minAngleRangeDeg = 30,
 this.minVariance = 1e-5,
 });

 /// Checks one rep given its [frames] and a function computing an angle
 /// (in degrees) from a frame (e.g. elbow angle for push-ups).
 CheatVerdict check(
 List<ProofFrame> frames, {
 double Function(ProofFrame)? angleOf,
 String trackedLandmark = 'nose',
 }) {
 if (frames.length < 2) return CheatVerdict.invalid;
 final duration = frames.last.timestamp
 .difference(frames.first.timestamp)
 .inMilliseconds;
 if (duration < minRepDurationMs) return CheatVerdict.suspect;

 if (angleOf != null) {
 final angles = [for (final f in frames) angleOf(f)];
 final range = angles.reduce((a, b) => a > b ? a : b) -
 angles.reduce((a, b) => a < b ? a : b);
 if (range < minAngleRangeDeg) return CheatVerdict.suspect;
 }

 final variance = _landmarkVariance(frames, trackedLandmark);
 if (variance < minVariance) return CheatVerdict.suspect;

 return CheatVerdict.clean;
 }

 double _landmarkVariance(List<ProofFrame> frames, String landmark) {
 final ys = <double>[];
 for (final f in frames) {
 final v = f.landmarks[landmark];
 if (v is List && v.length >= 2 && v[1] is num) {
 ys.add((v[1] as num).toDouble());
 }
 }
 if (ys.length < 2) return 0;
 final mean = ys.reduce((a, b) => a + b) / ys.length;
 final sumSq = ys.fold<double>(
 0, (acc, y) => acc + (y - mean) * (y - mean));
 return sumSq / ys.length;
 }
}