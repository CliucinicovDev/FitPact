import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/models/sync_queue_entry.dart';

void main() {
  final entry = SyncQueueEntry(
    id: 'q1',
    entityType: 'session',
    entityId: 's1',
    action: SyncAction.update,
    payload: {'repCount': 10},
    createdAt: DateTime(2026, 1, 1),
  );

  test('toJson/fromJson round trip', () {
    final restored = SyncQueueEntry.fromJson(entry.toJson());
    expect(restored.id, entry.id);
    expect(restored.entityType, 'session');
    expect(restored.action, SyncAction.update);
    expect(restored.payload, {'repCount': 10});
    expect(restored.status, SyncEntryStatus.pending);
    expect(restored.retryCount, 0);
  });

  test('copyWith changes only given fields', () {
    final updated = entry.copyWith(
        status: SyncEntryStatus.failed, retryCount: 3);
    expect(updated.status, SyncEntryStatus.failed);
    expect(updated.retryCount, 3);
    expect(updated.id, entry.id);
    expect(updated.action, SyncAction.update);
  });
}