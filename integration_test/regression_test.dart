import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';
import 'package:fitpact/core/anti_cheat/layer_1_on_device.dart';
import 'package:fitpact/core/anti_cheat/layer_2_on_device.dart';
import 'package:fitpact/core/models/challenge.dart';
import 'package:fitpact/core/models/workout_session.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/notifications/streak_notifier.dart';
import 'package:fitpact/core/proof/proof_generator.dart';

/// Regression suite: re-runs the critical unit behaviors through the
/// integration harness so failures surface on device/emulator builds.
void main() {
 IntegrationTestWidgetsFlutterBinding.ensureInitialized();

 testWidgets('regression: models round-trip', (tester) async {
 final session = WorkoutSession(
 id: 's1',
 userId: 'u1',
 exerciseType: ExerciseType.squat,
 startTime: DateTime(2026, 9, 19, 10),
 repCount: 15,
 formAverage: 0.9,
 );
 final restored = WorkoutSession.fromJson(session.toJson());
 expect(restored.exerciseType, ExerciseType.squat);
 expect(restored.repCount, 15);

 final challenge = Challenge(
 id: 'c1',
 title: 'Regression',
 exerciseType: ExerciseType.burpee,
 goalReps: 50,
 durationDays: 7,
 );
 final map = challenge.toMap();
 expect(Challenge.fromMap(map).title, 'Regression');
 });

 testWidgets('regression: streak milestones', (tester) async {
 final now = DateTime(2026, 9, 19, 12);
 final days = [
 for (var i = 0; i < 3; i++) DateTime(2026, 9, 17 + i),
 ];
 expect(StreakNotifier.computeStreak(days, now: now), 3);
 });

 testWidgets('regression: proof HMAC integrity', (tester) async {
 final gen = ProofGenerator(key: 'k');
 final base = DateTime(2026, 9, 19, 10);
 final frames = [
 for (var i = 0; i < 3; i++)
 ProofFrame(
 repIndex: 0,
 timestamp: base.add(Duration(milliseconds: 150 * i)),
 deviceId: 'd1',
 landmarks: {
 'nose': [0.5, 0.5 - 0.1 * i],
 },
 ),
 ];
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: frames);
 expect(gen.verify(proof), isTrue);
 });

 testWidgets('regression: anti-cheat layers accept clean input',
 (tester) async {
 final base = DateTime(2026, 9, 19, 10);
 final frames = [
 for (var i = 0; i < 4; i++)
 ProofFrame(
 repIndex: 0,
 timestamp: base.add(Duration(milliseconds: 150 * i)),
 deviceId: 'd1',
 landmarks: {
 'nose': [0.5, 0.5 - 0.1 * i],
 },
 ),
 ];
 expect(const Layer1OnDevice().check(frames), CheatVerdict.clean);
 expect(
 const Layer2OnDevice().check(frames,
 angleOf: (f) => 170 - (f.landmarks['nose'][1] as double) * 100),
 CheatVerdict.clean);
 });
}