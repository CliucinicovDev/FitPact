import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/models/sync_queue_entry.dart';
import 'package:fitpact/core/storage/sync_manager.dart';

SyncQueueEntry entry(String id) => SyncQueueEntry(
      id: id,
      entityType: 'session',
      entityId: id,
      action: SyncAction.create,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('processes queue in FIFO order', () async {
    final pushed = <String>[];
    final manager = SyncManager(
      push: (e) async {
        pushed.add(e.entityId);
        return SyncResult.success;
      },
    );
    manager
      ..enqueue(entry('a'))
      ..enqueue(entry('b'))
      ..enqueue(entry('c'));
    await manager.processQueue();
    expect(pushed, ['a', 'b', 'c']);
    expect(manager.pendingQueue, isEmpty);
    expect(manager.failedEntries, isEmpty);
  });

  test('retries with exponential backoff and succeeds', () async {
    var calls = 0;
    final manager = SyncManager(
      push: (e) async {
        calls++;
        return calls < 3 ? SyncResult.failure : SyncResult.success;
      },
    );
    manager.enqueue(entry('a'));
    await manager.processQueue();
    expect(calls, 3);
    expect(manager.pendingQueue, isEmpty);
    expect(manager.failedEntries, isEmpty);
  });

  test('marks entry failed after exhausting retries', () async {
    final notified = <String>[];
    final manager = SyncManager(
      push: (e) async => SyncResult.failure,
      onNotify: notified.add,
    );
    manager.enqueue(entry('a'));
    await manager.processQueue();
    expect(manager.failedEntries, hasLength(1));
    expect(manager.failedEntries.first.status, SyncEntryStatus.failed);
    expect(notified.length, 1);
    manager.clearFailed();
    expect(manager.failedEntries, isEmpty);
  });

  test('conflict resolves with server wins and notifies', () async {
    var notified = 0;
    final manager = SyncManager(
      push: (e) async => SyncResult.conflict,
      onNotify: (_) => notified++,
    );
    manager.enqueue(entry('a'));
    await manager.processQueue();
    expect(notified, 1);
    expect(manager.failedEntries, isEmpty);
    expect(manager.pendingQueue, isEmpty);
  });
}