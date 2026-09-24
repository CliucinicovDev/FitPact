import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';
import 'package:fitpact/core/proof/proof_generator.dart';

/// Layer 3 server-side checks: timestamp plausibility, HMAC integrity
/// and cross-check of the deviceId bound to the session.
class Layer3Server {
 final ProofGenerator verifier;
 final Duration maxClockSkew;
 final Duration maxRepDuration;

 const Layer3Server({
 required this.verifier,
 this.maxClockSkew = const Duration(minutes: 5),
 this.maxRepDuration = const Duration(minutes: 2),
 });

 /// Verifies a signed proof: HMAC must hold, timestamps must be ordered
 /// and near server time, and the deviceId must match the session's.
 Layer3Result check(
 Map<String, dynamic> proof, {
 required String expectedDeviceId,
 DateTime? now,
 }) {
 now ??= DateTime.now();

 if (!verifier.verify(proof)) {
 return const Layer3Result(
 CheatVerdict.suspect, 'HMAC signature mismatch');
 }

 final frames = (proof['frames'] as List)
 .map((f) => Map<String, dynamic>.from(f as Map))
 .toList()
 ..sort((a, b) => DateTime.parse(a['timestamp'] as String)
     .compareTo(DateTime.parse(b['timestamp'] as String)));
 if (frames.length < 3) {
 return const Layer3Result(
 CheatVerdict.suspect, 'Too few proof frames');
 }

 final firstTs = DateTime.parse(frames.first['timestamp'] as String);
 final lastTs = DateTime.parse(frames.last['timestamp'] as String);
 if (!firstTs.isBefore(lastTs) ||
     lastTs.isBefore(firstTs) ||
     lastTs.difference(firstTs) > maxRepDuration) {
 return const Layer3Result(
 CheatVerdict.suspect, 'Invalid rep timestamps');
 }
 final skew = now.difference(lastTs).abs();
 if (skew > maxClockSkew) {
 return const Layer3Result(
 CheatVerdict.suspect, 'Timestamp too far from server time');
 }

 final deviceIds = frames
 .map((f) => f['deviceId'] as String?)
 .toSet();
 if (deviceIds.length != 1 || deviceIds.first != expectedDeviceId) {
 return const Layer3Result(
 CheatVerdict.suspect, 'DeviceId mismatch');
 }

 return const Layer3Result(CheatVerdict.clean, 'OK');
 }
}