import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/notifications/streak_notifier.dart';

void main() {
 final now = DateTime(2026, 9, 19, 15);

 test('computeStreak counts consecutive days ending today', () {
 final days = [
 DateTime(2026, 9, 17),
 DateTime(2026, 9, 18),
 DateTime(2026, 9, 19),
 ];
 expect(StreakNotifier.computeStreak(days, now: now), 3);
 });

 test('computeStreak allows ending yesterday', () {
 final days = [
 DateTime(2026, 9, 16),
 DateTime(2026, 9, 18),
 ];
 expect(StreakNotifier.computeStreak(days, now: now), 1);
 });

 test('computeStreak returns 0 with a gap', () {
 final days = [
 DateTime(2026, 9, 10),
 DateTime(2026, 9, 11),
 ];
 expect(StreakNotifier.computeStreak(days, now: now), 0);
 });

 test('evaluate announces milestones without duplicates', () {
 final announced = <int>[];
 final notifier = StreakNotifier(onMilestone: announced.add);
 final days = [
 for (var i = 1; i <= 7; i++) DateTime(2026, 9, 12 + i),
 ];
 final first = notifier.evaluate(days, now: now);
 expect(first, containsAll([3, 7]));
 expect(announced, [3, 7]);
 final second = notifier.evaluate(days, now: now);
 expect(second, isEmpty);
 expect(announced, [3, 7]);
 });

 test('markAnnounced suppresses previously fired milestones', () {
 final announced = <int>[];
 final notifier = StreakNotifier(onMilestone: announced.add)
 ..markAnnounced(3);
 final days = [
 for (var i = 1; i <= 3; i++) DateTime(2026, 9, 16 + i),
 ];
 expect(notifier.evaluate(days, now: now), isEmpty);
 });
}