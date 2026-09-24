import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';
import 'package:fitpact/core/proof/proof_generator.dart';

/// Layer 1 on-device checks: capture frame-rate plausibility, landmark
/// movement plausibility and detection of identical (frozen) frames.
class Layer1OnDevice {
 /// Expected ms between frames during analysis.
 final int expectedFrameIntervalMs;
 /// Tolerated deviation from the expected interval.
 final int frameToleranceMs;
 /// Minimum euclidean movement of a landmark between frames to be
 /// considered real motion (in normalized coordinates).
 final double minMovement;
 /// Maximum euclidean movement considered physically plausible.
 final double maxMovement;

 const Layer1OnDevice({
 this.expectedFrameIntervalMs = 100,
 this.frameToleranceMs = 60,
 this.minMovement = 1e-4,
 this.maxMovement = 0.5,
 });

 /// Checks a rep's frames for frame-rate anomalies, frozen frames and
 /// implausible jumps.
 CheatVerdict check(List<ProofFrame> frames) {
 if (frames.length < 3) return CheatVerdict.invalid;
 var frozen = 0;
 for (var i = 1; i < frames.length; i++) {
 final dt = frames[i].timestamp
 .difference(frames[i - 1].timestamp)
 .inMilliseconds;
 if (dt <= 0) return CheatVerdict.suspect;
  if ((dt - expectedFrameIntervalMs).abs() > frameToleranceMs) {
  return CheatVerdict.suspect;
  }
 final d = _movement(frames[i - 1], frames[i]);
 if (d == 0) {
 frozen++;
 } else if (d > maxMovement) {
 return CheatVerdict.suspect;
 }
 }
 if (frozen >= frames.length - 1) return CheatVerdict.suspect;
 return CheatVerdict.clean;
 }

 double _movement(ProofFrame a, ProofFrame b) {
 final pa = a.landmarks['nose'];
 final pb = b.landmarks['nose'];
 if (pa is List && pb is List && pa.length >= 2 && pb.length >= 2) {
 final dx = (pa[0] as num).toDouble() - (pb[0] as num).toDouble();
 final dy = (pa[1] as num).toDouble() - (pb[1] as num).toDouble();
 return dx * dx + dy * dy;
 }
 return -1;
 }
}