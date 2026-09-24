import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/models/rep_record.dart';

void main() {
 final rep = RepRecord(
 id: 'r1',
 sessionId: 's1',
 timestamp: DateTime(2026, 1, 1, 10, 0, 1),
 phaseDurations: {'down': 800, 'up': 400},
 formScore: 0.9,
 feedbackMessage: 'Keep your back straight',
 landmarksJson: '{"nose": [0.1, 0.2]}',
 );

 test('toJson/fromJson round trip', () {
 final restored = RepRecord.fromJson(rep.toJson());
 expect(restored.id, 'r1');
 expect(restored.sessionId, 's1');
 expect(restored.timestamp, rep.timestamp);
 expect(restored.phaseDurations, {'down': 800, 'up': 400});
 expect(restored.formScore, 0.9);
 expect(restored.feedbackMessage, 'Keep your back straight');
 expect(restored.landmarksJson, isNotNull);
 });

 test('fromJson defaults optional fields', () {
 final restored = RepRecord.fromJson({
 'id': 'r2',
 'sessionId': 's1',
 'timestamp': DateTime(2026, 1, 1).toIso8601String(),
 });
 expect(restored.phaseDurations, isEmpty);
 expect(restored.formScore, 0);
 expect(restored.feedbackMessage, isNull);
 expect(restored.landmarksJson, isNull);
 });

 test('copyWith changes only given fields', () {
 final updated = rep.copyWith(formScore: 0.5);
 expect(updated.formScore, 0.5);
 expect(updated.id, 'r1');
 expect(updated.phaseDurations, {'down': 800, 'up': 400});
 });
}