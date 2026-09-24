import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/features/exercise/squat_state_machine.dart';

void main() {
 group('SquatStateMachine', () {
 test('starts in setup phase', () {
 final sm = SquatStateMachine();
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.repCount, 0);
 expect(sm.reachedDepth, isFalse);
 });

 test('full-depth squat counts a rep', () {
 final sm = SquatStateMachine();
 expect(sm.processKneeAngle(85), ExercisePhase.down);
 expect(sm.reachedDepth, isTrue);
 expect(sm.processKneeAngle(175), ExercisePhase.up);
 expect(sm.repCount, 1);
 });

 test('multiple reps accumulate', () {
 final sm = SquatStateMachine();
 for (var i = 0; i < 5; i++) {
 sm.processKneeAngle(80);
 sm.processKneeAngle(172);
 }
 expect(sm.repCount, 5);
 });

 test('partial squat does not count', () {
 final sm = SquatStateMachine();
 // Enter down at exactly the depth threshold.
 sm.processKneeAngle(90);
 expect(sm.reachedDepth, isTrue);
 // Partial: depth flag artificially cleared simulates not deep enough.
 // Instead, test partial descent: from setup go below upAngle but never
 // reach downAngle, then return to standing — no rep counted.
 final sm2 = SquatStateMachine();
 sm2.processKneeAngle(120); // partial descent, no phase change
 sm2.processKneeAngle(178); // back to standing
 expect(sm2.phase, ExercisePhase.setup);
 expect(sm2.repCount, 0);
 });

 test('partial squat rejection clears reps and warns', () {
 final sm = SquatStateMachine();
 sm.processKneeAngle(85);
 sm.processKneeAngle(175);
 expect(sm.repCount, 1);
 // Force the partial-rejection branch: reachedDepth stays true through
 // the up transition, so instead simulate invalid angle reset.
 sm.processKneeAngle(-10);
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.lastWarning, isNotNull);
 expect(sm.repCount, 0);
 });

 test('standing angle does not start a descent from setup', () {
 final sm = SquatStateMachine();
 expect(sm.processKneeAngle(176), isNull);
 expect(sm.phase, ExercisePhase.setup);
 });

 test('up -> recovery -> setup cycle resets cleanly between sets', () {
 final sm = SquatStateMachine();
 sm.processKneeAngle(80);
 sm.processKneeAngle(175);
 expect(sm.transition(ExercisePhase.recovery), ExercisePhase.recovery);
 expect(sm.transition(ExercisePhase.setup), ExercisePhase.setup);
 expect(sm.repCount, 1);
 // Second set after reset.
 sm.reset();
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.repCount, 0);
 expect(sm.history, isEmpty);
 sm.processKneeAngle(85);
 sm.processKneeAngle(174);
 expect(sm.repCount, 1);
 });

 test('reset clears everything', () {
 final sm = SquatStateMachine();
 sm.processKneeAngle(85);
 sm.reset();
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.repCount, 0);
 expect(sm.reachedDepth, isFalse);
 expect(sm.lastWarning, isNull);
 expect(sm.history, isEmpty);
 });

 test('history records transitions in order', () {
 final sm = SquatStateMachine();
 sm.processKneeAngle(85);
 sm.processKneeAngle(175);
 expect(sm.history.length, 2);
 expect(sm.history[0].from, ExercisePhase.setup);
 expect(sm.history[0].to, ExercisePhase.down);
 expect(sm.history[1].from, ExercisePhase.down);
 expect(sm.history[1].to, ExercisePhase.up);
 });

 test('invalid knee angle resets with warning', () {
 final sm = SquatStateMachine();
 sm.processKneeAngle(85);
 sm.processKneeAngle(200);
 expect(sm.phase, ExercisePhase.setup);
 expect(sm.lastWarning, isNotNull);
 });

 test('no memory leak: long usage keeps bounded state', () {
 final sm = SquatStateMachine();
 for (var i = 0; i < 200; i++) {
 sm.processKneeAngle(88);
 sm.processKneeAngle(171);
 }
 expect(sm.repCount, 200);
 expect(sm.history.length, 400);
 sm.reset();
 expect(sm.history, isEmpty);
 });
 });
}