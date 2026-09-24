import 'dart:math';

/// A challenge room created or joined by the user.
class ChallengeRoom {
  final String id;
  final String name;
  final String exerciseType;
  final int days;
  final String inviteCode;
  final bool isMine;

  const ChallengeRoom({
    required this.id,
    required this.name,
    required this.exerciseType,
    required this.days,
    required this.inviteCode,
    required this.isMine,
  });
}

/// Simple in-memory store for challenge rooms. Replace with the
/// Supabase-backed repository once the backend is wired in main.
class ChallengeStore {
  ChallengeStore._();

  static final ChallengeStore instance = ChallengeStore._();

  final List<ChallengeRoom> _all = [];
  final List<ChallengeRoom> _joined = [];

  static const String _alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars

  List<ChallengeRoom> get all => List.unmodifiable(_all);
  List<ChallengeRoom> get joined => List.unmodifiable(_joined);

  /// Creates a new challenge room owned by the current user.
  ChallengeRoom create({
    required String name,
    required String exerciseType,
    required int days,
  }) {
    final code = _generateCode();
    final room = ChallengeRoom(
      id: 'c${_all.length + _joined.length + 1}_$code',
      name: name,
      exerciseType: exerciseType,
      days: days,
      inviteCode: code,
      isMine: true,
    );
    _all.add(room);
    return room;
  }

  /// Joins a room by its 6-char invite code. Returns the room or null.
  ChallengeRoom? joinByCode(String code) {
    final normalized = code.trim().toUpperCase();
    final room = [..._all, ..._joined]
        .where((c) => c.inviteCode == normalized)
        .firstOrNull;
    if (room == null || _joined.contains(room)) return room;
    _joined.add(room);
    return room;
  }

  String _generateCode() => String.fromCharCodes(Iterable.generate(
      6,
      (_) => _alphabet.codeUnitAt(
          Random.secure().nextInt(_alphabet.length))));
}