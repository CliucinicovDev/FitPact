import 'package:fitpact/core/enums/exercise_enums.dart';

/// Status of a challenge lifecycle.
enum ChallengeStatus { active, completed, cancelled }

/// An immutable challenge entity.
class Challenge {
  final String id;
  final String title;
  final ExerciseType exerciseType;
  final int goalReps;
  final int durationDays;
  final ChallengeStatus status;
  final String? inviteCode;
  final String? createdBy;
  final DateTime? createdAt;

  const Challenge({
    required this.id,
    required this.title,
    required this.exerciseType,
    required this.goalReps,
    required this.durationDays,
    this.status = ChallengeStatus.active,
    this.inviteCode,
    this.createdBy,
    this.createdAt,
  });

  Challenge copyWith({
    String? id,
    String? title,
    ExerciseType? exerciseType,
    int? goalReps,
    int? durationDays,
    ChallengeStatus? status,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      Challenge(
        id: id ?? this.id,
        title: title ?? this.title,
        exerciseType: exerciseType ?? this.exerciseType,
        goalReps: goalReps ?? this.goalReps,
        durationDays: durationDays ?? this.durationDays,
        status: status ?? this.status,
        inviteCode: inviteCode ?? this.inviteCode,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as String,
        title: map['title'] as String,
        exerciseType: ExerciseType.values.byName(map['exercise_type'] as String),
        goalReps: (map['goal_reps'] as num).toInt(),
        durationDays: (map['duration_days'] as num).toInt(),
        status: ChallengeStatus.values
            .byName((map['status'] as String?) ?? ChallengeStatus.active.name),
        inviteCode: map['invite_code'] as String?,
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'exercise_type': exerciseType.name,
        'goal_reps': goalReps,
        'duration_days': durationDays,
        'status': status.name,
        'invite_code': inviteCode,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
      };
}