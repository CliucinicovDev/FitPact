import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One landmark snapshot inside a proof, captured mid-rep.
class ProofFrame {
  final int repIndex;
  final DateTime timestamp;
  final String deviceId;
  final Map<String, dynamic> landmarks;

  const ProofFrame({
    required this.repIndex,
    required this.timestamp,
    required this.deviceId,
    required this.landmarks,
  });

  Map<String, dynamic> toJson() => {
        'repIndex': repIndex,
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'landmarks': landmarks,
      };
}

/// Builds tamper-evident proofs: 3-5 landmark snapshots per rep as a JSON
/// array of ProofFrame, signed with HMAC-SHA256 over a canonical encoding.
class ProofGenerator {
  /// Secret used to derive the HMAC key (device/user specific on server).
  final List<int> keyBytes;

  ProofGenerator({required String key}) : keyBytes = utf8.encode(key);

  /// Derives a stable key from userId + salt, so signatures are bound to
  /// the user and can be re-derived for verification.
  static String deriveKey(String userId, String salt) => '$userId:$salt';

  /// Builds the signed proof for one rep from its [frames].
  /// Expects between 3 and 5 frames.
  Map<String, dynamic> generate({
    required String sessionId,
    required int repIndex,
    required List<ProofFrame> frames,
  }) {
    if (frames.length < 3 || frames.length > 5) {
      throw ArgumentError('A proof needs 3-5 frames, got ${frames.length}');
    }
    final canonical = _canonicalize(sessionId, repIndex, frames);
    final signature =
        Hmac(sha256, keyBytes).convert(utf8.encode(canonical)).toString();
    return {
      'sessionId': sessionId,
      'repIndex': repIndex,
      'frames': [for (final f in frames) f.toJson()],
      'hmacSignature': signature,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Verifies the integrity of a stored proof document.
  bool verify(Map<String, dynamic> proof) {
    final sessionId = proof['sessionId'] as String;
    final repIndex = proof['repIndex'] as int;
    final frames = [
      for (final f in (proof['frames'] as List))
        ProofFrame(
          repIndex: f['repIndex'] as int,
          timestamp: DateTime.parse(f['timestamp'] as String),
          deviceId: f['deviceId'] as String,
          landmarks: f['landmarks'] as Map<String, dynamic>,
        ),
    ];
    final expected =
        Hmac(sha256, keyBytes).convert(utf8.encode(_canonicalize(sessionId, repIndex, frames))).toString();
    return expected == proof['hmacSignature'];
  }

  /// Canonical, deterministic encoding of the signed payload: frames are
  /// sorted by timestamp and keys are sorted so JSON maps are stable.
  String _canonicalize(
      String sessionId, int repIndex, List<ProofFrame> frames) {
    final sorted = [...frames]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final buf = StringBuffer('$sessionId|$repIndex');
    for (final f in sorted) {
      final lm = json.encode(_sortedMap(f.landmarks));
      buf.write('|${f.repIndex}:${f.timestamp.toIso8601String()}:${f.deviceId}:$lm');
    }
    return buf.toString();
  }

  Map<String, dynamic> _sortedMap(Map<String, dynamic> map) {
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]};
  }
}