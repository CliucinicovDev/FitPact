import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/repositories/challenge_repository.dart';

/// Minimal fake of the Supabase query-builder surface used by the repo.
class _FakeClient {
  final List<Map<String, dynamic>> _challenges = [];
  final List<Map<String, dynamic>> _members = [];
  final String? newId;

  _FakeClient({this.newId});

  dynamic from(String table) =>
      _Table(table == 'challenges' ? _challenges : _members, newId);
}

class _Table {
  final List<Map<String, dynamic>> _rows;
  final String? newId;
  _Table(this._rows, this.newId);

  dynamic insert(Map<String, dynamic> payload) =>
      _Insert(payload, _rows, newId);
  dynamic select(String cols) => _Select(_rows);
  dynamic delete() => _Delete();
}

class _Insert {
  final Map<String, dynamic> _payload;
  final List<Map<String, dynamic>> _rows;
  final String? newId;
  _Insert(this._payload, this._rows, this.newId);

  _Insert select() => this;
  Future<Map<String, dynamic>> single() async {
    _rows.add({..._payload, 'id': newId ?? 'x'});
    return _rows.last;
  }
}

class _Select implements Future<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _rows;
  _Select(this._rows);

  _Select eq(String col, Object? value) => this;
  _Select order(String col, {bool ascending = true}) => this;
  Future<List<Map<String, dynamic>>> get _done async => _rows;

  @override
  Future<R> then<R>(FutureOr<R> Function(List<Map<String, dynamic>>) onValue,
          {Function? onError}) =>
      _done.then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _done.catchError(onError, test: test);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
          void Function() action) =>
      _done.whenComplete(action);

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _done.asStream();

  @override
  Future<List<Map<String, dynamic>>> timeout(Duration timeLimit,
          {FutureOr<List<Map<String, dynamic>>> Function()? onTimeout}) =>
      _done.timeout(timeLimit, onTimeout: onTimeout);
}

class _Delete {
  _Delete eq(String col, Object? value) => this;
  Future<List<Map<String, dynamic>>> get() async => const [];
}

void main() {
  test('createChallenge validates inputs', () {
    final repo = ChallengeRepository(client: _FakeClient(newId: 'c1'));
    expect(
        () => repo.createChallenge(
            title: '', exerciseType: 'pushUp',
            goalReps: 100, durationDays: 30, createdBy: 'u1'),
        throwsArgumentError);
    expect(
        () => repo.createChallenge(
            title: 'T', exerciseType: 'pushUp',
            goalReps: 0, durationDays: 30, createdBy: 'u1'),
        throwsArgumentError);
    expect(
        () => repo.createChallenge(
            title: 'T', exerciseType: 'pushUp',
            goalReps: 100, durationDays: 91, createdBy: 'u1'),
        throwsArgumentError);
  });

  test('createChallenge inserts challenge and membership', () async {
    final client = _FakeClient(newId: 'c1');
    final repo = ChallengeRepository(client: client);
    final c = await repo.createChallenge(
        title: 'Push-up war', exerciseType: 'pushUp',
        goalReps: 1000, durationDays: 30, createdBy: 'u1',
        inviteCode: 'ABC123');
    expect(c.id, 'c1');
    expect(c.title, 'Push-up war');
  });

  test('joinChallenge rejects duplicate membership', () async {
    final client = _FakeClient(newId: 'c1');
    await client.from('challenge_members').insert(
        {'challenge_id': 'c1', 'profile_id': 'u1'}).select().single();
    final repo = ChallengeRepository(client: client);
    await expectLater(
        repo.joinChallenge(challengeId: 'c1', profileId: 'u1'),
        throwsStateError);
  });

  test('leaveChallenge deletes membership without error', () async {
    final client = _FakeClient();
    final repo = ChallengeRepository(client: client);
    await repo.leaveChallenge(challengeId: 'c1', profileId: 'u1');
  });
}