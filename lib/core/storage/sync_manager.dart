import 'dart:async';

import 'package:fitpact/core/models/sync_queue_entry.dart';

/// Outcome of one attempted sync push.
enum SyncResult { success, failure, conflict }

/// Pushes queued entries to a remote endpoint in FIFO order with
/// exponential-backoff retries (max 3) and last-write-wins conflict
/// resolution (server wins).
class SyncManager {
 /// Maximum number of retries per entry.
 static const int maxRetries = 3;

 final Future<SyncResult> Function(SyncQueueEntry entry) push;
 final void Function(String message)? onNotify;

 final List<SyncQueueEntry> _queue = [];
 final List<SyncQueueEntry> _failed = [];
 bool _processing = false;

 SyncManager({required this.push, this.onNotify});

 /// Entries waiting to be synced, in FIFO order.
 List<SyncQueueEntry> get pendingQueue => List.unmodifiable(_queue);

 /// Entries permanently failed after exhausting retries.
 List<SyncQueueEntry> get failedEntries => List.unmodifiable(_failed);

 /// Enqueues an entry at the end of the FIFO queue.
 void enqueue(SyncQueueEntry entry) {
 _queue.add(entry.copyWith(status: SyncEntryStatus.pending, retryCount: 0));
 }

 /// Processes the queue until empty or an entry exhausts retries.
 ///
 /// Retries use exponential backoff: 1s, 2s, 4s. On conflict the server
 /// version wins (entry marked synced) and the user is notified.
 Future<void> processQueue() async {
 if (_processing) return;
 _processing = true;
 try {
 while (_queue.isNotEmpty) {
 var entry = _queue.first;
 var attempt = 0;
 var result = await push(_markSyncing(entry));
 while (result == SyncResult.failure && attempt < maxRetries) {
 attempt++;
 entry = entry.copyWith(
 status: SyncEntryStatus.pending, retryCount: attempt);
 await Future<void>.delayed(
 Duration(seconds: 1 << (attempt - 1)));
 result = await push(_markSyncing(entry));
 }
 _queue.removeAt(0);
 switch (result) {
 case SyncResult.success:
 break;
 case SyncResult.conflict:
 // Last-write-wins: server wins.
 onNotify?.call(
 'Conflict on ${entry.entityType} ${entry.entityId}: '
 'server version kept');
 break;
 case SyncResult.failure:
 entry = entry.copyWith(status: SyncEntryStatus.failed);
 _failed.add(entry);
 onNotify?.call(
 'Failed to sync ${entry.entityType} ${entry.entityId}');
 break;
 }
 }
 } finally {
 _processing = false;
 }
 }

 SyncQueueEntry _markSyncing(SyncQueueEntry entry) =>
 entry.copyWith(status: SyncEntryStatus.syncing);

 /// Clears the failed list (e.g. after user review).
 void clearFailed() => _failed.clear();
}