/// An immutable challenge membership entity.
class ChallengeMember {
  final String id;
  final String challengeId;
  final String profileId;
  final DateTime? joinedAt;
  final int totalReps;
  final int livesRemaining;

  const ChallengeMember({
    required this.id,
    required this.challengeId,
    required this.profileId,
    this.joinedAt,
    this.totalReps = 0,
    this.livesRemaining = 3,
  });

  ChallengeMember copyWith({
    String? id,
    String? challengeId,
    String? profileId,
    DateTime? joinedAt,
    int? totalReps,
    int? livesRemaining,
  }) =>
      ChallengeMember(
        id: id ?? this.id,
        challengeId: challengeId ?? this.challengeId,
        profileId: profileId ?? this.profileId,
        joinedAt: joinedAt ?? this.joinedAt,
        totalReps: totalReps ?? this.totalReps,
        livesRemaining: livesRemaining ?? this.livesRemaining,
      );

  factory ChallengeMember.fromMap(Map<String, dynamic> map) => ChallengeMember(
        id: map['id'] as String,
        challengeId: map['challenge_id'] as String,
        profileId: map['profile_id'] as String,
        joinedAt: map['joined_at'] == null
            ? null
            : DateTime.parse(map['joined_at'] as String).toLocal(),
        totalReps: (map['total_reps'] as num?)?.toInt() ?? 0,
        livesRemaining: (map['lives_remaining'] as num?)?.toInt() ?? 3,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'challenge_id': challengeId,
        'profile_id': profileId,
        'joined_at': joinedAt?.toIso8601String(),
        'total_reps': totalReps,
        'lives_remaining': livesRemaining,
      };
}