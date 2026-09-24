import 'package:fitpact/core/enums/exercise_enums.dart';

/// An immutable recorded workout session.
class WorkoutSession {
  final String id;
  final String userId;
  final ExerciseType exerciseType;
  final DateTime startTime;
  final DateTime? endTime;
  final int repCount;
  final double formAverage;
  final SyncStatus status;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.exerciseType,
    required this.startTime,
    this.endTime,
    this.repCount = 0,
    this.formAverage = 0,
    this.status = SyncStatus.pending,
  });

  WorkoutSession copyWith({
    String? id,
    String? userId,
    ExerciseType? exerciseType,
    DateTime? startTime,
    DateTime? endTime,
    int? repCount,
    double? formAverage,
    SyncStatus? status,
  }) =>
      WorkoutSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        exerciseType: exerciseType ?? this.exerciseType,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        repCount: repCount ?? this.repCount,
        formAverage: formAverage ?? this.formAverage,
        status: status ?? this.status,
      );

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      WorkoutSession(
        id: json['id'] as String,
        userId: json['userId'] as String,
        exerciseType: ExerciseType.values.byName(json['exerciseType'] as String),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] == null
            ? null
            : DateTime.parse(json['endTime'] as String),
        repCount: (json['repCount'] as num?)?.toInt() ?? 0,
        formAverage: (json['formAverage'] as num?)?.toDouble() ?? 0,
        status: SyncStatus.values
            .byName((json['status'] as String?) ?? SyncStatus.pending.name),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'exerciseType': exerciseType.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'repCount': repCount,
        'formAverage': formAverage,
        'status': status.name,
      };
}