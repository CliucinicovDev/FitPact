import 'dart:collection';

/// Computes workout streaks (consecutive training days) and fires a
/// notification callback at milestones (3, 7, 14, 30, 60) without
/// duplicates.
class StreakNotifier {
  static const List<int> milestones = [3, 7, 14, 30, 60];

  /// Callback fired when a milestone is newly reached.
  final void Function(int streak) onMilestone;

  final Set<int> _announced = {};

  StreakNotifier({required this.onMilestone});

  /// Given the distinct training days (local dates, any order), computes
  /// the current streak: the number of consecutive days ending today or
  /// yesterday.
  static int computeStreak(
      List<DateTime> trainingDays, {DateTime? now}) {
    final days = SplayTreeSet<DateTime>.from(
        trainingDays.map((d) => DateTime(d.year, d.month, d.day)));
    final n = now ?? DateTime.now();
    var today = DateTime(n.year, n.month, n.day);

    var streak = 0;
    var cursor = today;
    // The streak may end yesterday if today's workout is not done yet.
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Evaluates the streak and announces newly reached milestones.
  /// Returns the list of milestones announced this call (possibly empty).
  List<int> evaluate(List<DateTime> trainingDays, {DateTime? now}) {
    final streak = computeStreak(trainingDays, now: now);
    final announced = <int>[];
    for (final m in milestones) {
      if (streak >= m && !_announced.contains(m)) {
        _announced.add(m);
        announced.add(m);
        onMilestone(m);
      }
    }
    return announced;
  }

  /// Marks a milestone as already announced (restored from storage).
  void markAnnounced(int milestone) => _announced.add(milestone);

  /// Forgets announced milestones (streak reset / new user).
  void reset() => _announced.clear();
}