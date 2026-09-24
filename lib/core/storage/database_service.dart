import 'dart:convert';

import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/models/rep_record.dart';
import 'package:fitpact/core/models/workout_session.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite persistence for workout sessions and rep records, with
/// transaction support and indexed queries.
class LocalDatabaseService {
 static const String sessionsTable = 'workout_sessions';
 static const String repsTable = 'rep_records';

 final Database? _owningDb;
  final DatabaseExecutor _db;

  LocalDatabaseService._(this._db, [this._owningDb]);

 /// Opens the database (creating the schema) at [path]; when [path] is
 /// null a file named `fitpact.db` is created in the default location.
 static Future<LocalDatabaseService> open({String? path}) async {
 final dbPath = path ?? p.join(await getDatabasesPath(), 'fitpact.db');
 final db = await openDatabase(
 dbPath,
 version: 1,
  onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
  onCreate: (db, version) async {
 await db.execute('''
 CREATE TABLE $sessionsTable (
 id TEXT PRIMARY KEY,
 userId TEXT NOT NULL,
 exerciseType TEXT NOT NULL,
 startTime TEXT NOT NULL,
 endTime TEXT,
 repCount INTEGER NOT NULL DEFAULT 0,
 formAverage REAL NOT NULL DEFAULT 0,
 status TEXT NOT NULL DEFAULT 'pending'
 )
 ''');
 await db.execute('''
 CREATE INDEX idx_sessions_user_start
 ON $sessionsTable (userId, startTime)
 ''');
 await db.execute('''
 CREATE TABLE $repsTable (
 id TEXT PRIMARY KEY,
 sessionId TEXT NOT NULL,
 timestamp TEXT NOT NULL,
 phaseDurations TEXT NOT NULL DEFAULT '{}',
 formScore REAL NOT NULL DEFAULT 0,
 feedbackMessage TEXT,
 landmarksJson TEXT,
 FOREIGN KEY (sessionId) REFERENCES $sessionsTable (id)
 ON DELETE CASCADE
 )
 ''');
 await db.execute('''
 CREATE INDEX idx_reps_session_ts
 ON $repsTable (sessionId, timestamp)
 ''');
 },
 );
 return LocalDatabaseService._(db);
 }

 /// Inserts a [session]; replaces on id conflict.
 Future<void> insertSession(WorkoutSession session) async {
 await _db.insert(
 sessionsTable,
 _sessionRow(session),
 conflictAlgorithm: ConflictAlgorithm.replace,
 );
 }

 /// Updates an existing session. Returns the affected row count.
 Future<int> updateSession(WorkoutSession session) async =>
 await _db.update(sessionsTable, _sessionRow(session),
 where: 'id = ?', whereArgs: [session.id]);

 /// Deletes a session and (via cascade) its reps.
 Future<int> deleteSession(String id) async =>
 await _db.delete(sessionsTable, where: 'id = ?', whereArgs: [id]);

 /// Fetches a session by id, or null.
 Future<WorkoutSession?> getSessionById(String id) async {
 final rows = await _db
 .query(sessionsTable, where: 'id = ?', whereArgs: [id], limit: 1);
 if (rows.isEmpty) return null;
 return _sessionFromRow(rows.first);
 }

 /// Fetches all sessions for [userId], newest first.
 Future<List<WorkoutSession>> getAllSessions(String userId) async {
 final rows = await _db.query(
 sessionsTable,
 where: 'userId = ?',
 whereArgs: [userId],
 orderBy: 'startTime DESC',
 );
 return [for (final r in rows) _sessionFromRow(r)];
 }

 /// Inserts a [record]; replaces on id conflict.
 Future<void> insertRep(RepRecord record) async {
 await _db.insert(repsTable, _repRow(record),
 conflictAlgorithm: ConflictAlgorithm.replace);
 }

 /// Updates an existing rep record. Returns the affected row count.
 Future<int> updateRep(RepRecord record) async =>
 await _db.update(repsTable, _repRow(record),
 where: 'id = ?', whereArgs: [record.id]);

 /// Deletes a rep record.
 Future<int> deleteRep(String id) async =>
 await _db.delete(repsTable, where: 'id = ?', whereArgs: [id]);

 /// Fetches a rep record by id, or null.
 Future<RepRecord?> getRepById(String id) async {
 final rows = await _db
 .query(repsTable, where: 'id = ?', whereArgs: [id], limit: 1);
 if (rows.isEmpty) return null;
 return _repFromRow(rows.first);
 }

 /// Fetches all rep records of a session, oldest first.
 Future<List<RepRecord>> getRepsForSession(String sessionId) async {
 final rows = await _db.query(
 repsTable,
 where: 'sessionId = ?',
 whereArgs: [sessionId],
 orderBy: 'timestamp ASC',
 );
 return [for (final r in rows) _repFromRow(r)];
 }

 /// Sessions for [userId] whose start lies within [from]-[to].
 Future<List<WorkoutSession>> getSessionsByDateRange(
 String userId, DateTime from, DateTime to) async {
 final rows = await _db.query(
 sessionsTable,
 where: 'userId = ? AND startTime >= ? AND startTime <= ?',
 whereArgs: [
 userId,
 from.toIso8601String(),
 to.toIso8601String(),
 ],
 orderBy: 'startTime DESC',
 );
 return [for (final r in rows) _sessionFromRow(r)];
 }

 /// Sessions still pending or failed sync.
 Future<List<WorkoutSession>> getUnsyncedSessions(String userId) async {
 final rows = await _db.query(
 sessionsTable,
 where: "userId = ? AND status IN ('pending', 'failed')",
 whereArgs: [userId],
 orderBy: 'startTime ASC',
 );
 return [for (final r in rows) _sessionFromRow(r)];
 }

 /// The last [n] sessions for [userId], newest first.
 Future<List<WorkoutSession>> getLastNSessions(String userId, int n) async {
 final rows = await _db.query(
 sessionsTable,
 where: 'userId = ?',
 whereArgs: [userId],
 orderBy: 'startTime DESC',
 limit: n,
 );
 return [for (final r in rows) _sessionFromRow(r)];
 }

 /// Distinct days (local dates) on which the user trained, oldest first.
 Future<List<DateTime>> getStreakData(String userId) async {
 final rows = await _db.query(
 sessionsTable,
 columns: ['DISTINCT startTime'],
 where: 'userId = ?',
 whereArgs: [userId],
 orderBy: 'startTime ASC',
 );
 final days = <DateTime>{};
 for (final r in rows) {
 final start = DateTime.parse(r['startTime'] as String);
 days.add(DateTime(start.year, start.month, start.day));
 }
 return days.toList()..sort();
 }

 /// Runs [action] inside a transaction.
 Future<T> inTransaction<T>(
 Future<T> Function(LocalDatabaseService txn) action) async {
 return await _owningDb!.transaction((raw) async {
 final txn = LocalDatabaseService._(raw);
 return await action(txn);
 });
 }

 /// Closes the database.
 Future<void> close() async => await _owningDb?.close();

 Map<String, dynamic> _sessionRow(WorkoutSession s) => {
 'id': s.id,
 'userId': s.userId,
 'exerciseType': s.exerciseType.name,
 'startTime': s.startTime.toIso8601String(),
 'endTime': s.endTime?.toIso8601String(),
 'repCount': s.repCount,
 'formAverage': s.formAverage,
 'status': s.status.name,
 };

 WorkoutSession _sessionFromRow(Map<String, dynamic> row) =>
 WorkoutSession(
 id: row['id'] as String,
 userId: row['userId'] as String,
 exerciseType: ExerciseType.values.byName(row['exerciseType'] as String),
 startTime: DateTime.parse(row['startTime'] as String),
 endTime: row['endTime'] == null
 ? null
 : DateTime.parse(row['endTime'] as String),
 repCount: row['repCount'] as int,
 formAverage: (row['formAverage'] as num).toDouble(),
 status: SyncStatus.values.byName(row['status'] as String),
 );

 Map<String, dynamic> _repRow(RepRecord r) => {
 'id': r.id,
 'sessionId': r.sessionId,
 'timestamp': r.timestamp.toIso8601String(),
 'phaseDurations': jsonEncode(r.phaseDurations),
 'formScore': r.formScore,
 'feedbackMessage': r.feedbackMessage,
 'landmarksJson': r.landmarksJson,
 };

 RepRecord _repFromRow(Map<String, dynamic> row) => RepRecord(
 id: row['id'] as String,
 sessionId: row['sessionId'] as String,
 timestamp: DateTime.parse(row['timestamp'] as String),
 phaseDurations: _decodePhases(row['phaseDurations'] as String),
 formScore: (row['formScore'] as num).toDouble(),
 feedbackMessage: row['feedbackMessage'] as String?,
 landmarksJson: row['landmarksJson'] as String?,
 );

 Map<String, int> _decodePhases(String raw) {
 final map = jsonDecode(raw) as Map<String, dynamic>;
 return {for (final e in map.entries) e.key: (e.value as num).toInt()};
 }
}