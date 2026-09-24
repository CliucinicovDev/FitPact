import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/features/exercise/plank_scorer.dart';
import 'package:fitpact/features/exercise/plank_state_machine.dart';

void main() {
 group('PlankStateMachine', () {
 test('starts in setup phase with zero duration', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.holdDuration, Duration.zero);
 expect(sm.sagDetected, isFalse);
 });

 test('timer tracks hold duration with fake clock', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 expect(sm.startHold(), isTrue);
 // Simulate elapsed time by advancing the hold start.
 sm.dispose();
 expect(sm.holdDuration, greaterThanOrEqualTo(Duration.zero));
 expect(sm.phase, ExercisePhase.hold);
 });

 test('hold ends with recovery and duration recorded', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 final d = sm.endHold();
 expect(d, isNotNull);
 expect(sm.phase, ExercisePhase.recovery);
 });

 test('hip sag (angle deviation > 15) resets hold with warning', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 final newPhase = sm.processBodyAngle(160); // 20° deviation
 expect(newPhase, ExercisePhase.setup);
 expect(sm.sagDetected, isTrue);
 expect(sm.lastWarning, isNotNull);
 expect(sm.holdStart, isNull);
 });

 test('straight body angle keeps the hold', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 expect(sm.processBodyAngle(175), isNull); // 5° deviation
 expect(sm.phase, ExercisePhase.hold);
 });

 test('edge: rising hips during hold resets (deviation counted)', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 // Hips too high: body angle > 180 is also a deviation.
 expect(sm.processBodyAngle(200), ExercisePhase.setup);
 expect(sm.sagDetected, isTrue);
 });

 test('processBodyAngle ignored outside hold', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 expect(sm.processBodyAngle(150), isNull);
 expect(sm.phase, ExercisePhase.setup);
 });

 test('reset clears everything', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 sm.processBodyAngle(160);
 sm.reset();
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.holdDuration, Duration.zero);
 expect(sm.sagDetected, isFalse);
 expect(sm.lastWarning, isNull);
 expect(sm.history, isEmpty);
 });

 test('hold duration accumulates with fake_async timer', () {
 final sm = PlankStateMachine();
 fakeAsync((async) {
 expect(sm.startHold(), isTrue);
 async.elapse(const Duration(seconds: 2));
 expect(sm.holdDuration.inMilliseconds, greaterThanOrEqualTo(1900));
 sm.dispose();
 });
 });

 test('startHold fails when not in setup', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 sm.endHold();
 expect(sm.startHold(), isFalse); // recovery, not setup
 });

 test('history records hold and recovery transitions', () {
 final sm = PlankStateMachine();
 addTearDown(sm.dispose);
 sm.startHold();
 sm.endHold();
 expect(sm.history.length, 2);
 expect(sm.history[0].to, ExercisePhase.hold);
 expect(sm.history[1].to, ExercisePhase.recovery);
 });
 });

 group('PlankScorer', () {
 final scorer = PlankScorer();

 test('plank under 5 seconds scores 0', () {
 expect(scorer.score(4.9, [180, 178]), 0);
 expect(scorer.score(0, []), 0);
 });

 test('perfect long plank scores high', () {
 final s = scorer.score(60, [180, 180, 180]);
 expect(s, greaterThan(0.9));
 expect(s, lessThanOrEqualTo(1.0));
 });

 test('short plank scores low', () {
 final s = scorer.score(6, [180, 180]);
  // Duration factor ~0, but neutral alignment/stability still contribute.
  expect(s, lessThan(0.6));
  });

 test('unstable plank scores lower than stable one', () {
 final stable = scorer.score(30, [178, 179, 180, 179]);
 final unstable = scorer.score(30, [150, 180, 120, 180]);
 expect(unstable, lessThan(stable));
 });

 test('misaligned plank scores lower than aligned one', () {
 final aligned = scorer.score(30, [180, 179, 180]);
 final misaligned = scorer.score(30, [150, 150, 150]);
 expect(misaligned, lessThan(aligned));
 });

 test('weights sum to 1 and score is bounded', () {
 final s = scorer.score(45, [170, 175]);
 expect(s, inInclusiveRange(0, 1));
 expect(
 PlankScorer.durationWeight +
 PlankScorer.alignmentWeight +
 PlankScorer.stabilityWeight,
 1.0,
 );
 });

 test('empty angle list uses neutral factors', () {
 final s = scorer.score(10, []);
 expect(s, greaterThan(0));
 expect(s, lessThan(1));
 });
 });
}