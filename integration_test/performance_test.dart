import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fitpact/core/models/sync_queue_entry.dart';
import 'package:fitpact/core/storage/sync_manager.dart';
import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';
import 'package:fitpact/core/anti_cheat/layer_1_on_device.dart';
import 'package:fitpact/core/proof/proof_generator.dart';

/// Performance and stability checks: sustained frame processing (1000
/// frames) with no accumulation, and an offline queue that drains and
/// retries correctly.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('performance: 1000 frames processed by Layer 1', (tester) async {
    const layer = Layer1OnDevice();
    final base = DateTime(2026, 9, 19, 10);
    var suspect = 0;
    var clean = 0;

    // 200 reps x 5 frames = 1000 frames in windows of 5.
    for (var rep = 0; rep < 200; rep++) {
      final start = base.add(Duration(milliseconds: 800 * rep));
      final frames = [
        for (var i = 0; i < 5; i++)
          ProofFrame(
            repIndex: rep,
            timestamp: start.add(Duration(milliseconds: 150 * i)),
            deviceId: 'd1',
            landmarks: {
              'nose': [0.5 + 0.001 * i, 0.5 - 0.05 * i],
            },
          ),
      ];
      final verdict = layer.check(frames);
      if (verdict == CheatVerdict.clean) {
        clean++;
      } else {
        suspect++;
      }
    }

    expect(suspect, 0, reason: 'clean input must not be flagged');
    expect(clean, 200);
  });

  testWidgets('performance: offline queue drains without leaks',
      (tester) async {
    final pushed = <String>[];
    final manager = SyncManager(
      push: (e) async {
        pushed.add(e.entityId);
        return SyncResult.success;
      },
    );

    // Simulate an offline burst: enqueue 300 entries, then go online.
    for (var i = 0; i < 300; i++) {
      manager.enqueue(SyncQueueEntry(
        id: 'q$i',
        entityType: 'rep',
        entityId: 'r$i',
        action: SyncAction.create,
        createdAt: DateTime.now(),
      ));
    }
    expect(manager.pendingQueue, hasLength(300));

    final sw = Stopwatch()..start();
    await manager.processQueue();
    sw.stop();

    expect(pushed, hasLength(300));
    expect(manager.pendingQueue, isEmpty);
    expect(manager.failedEntries, isEmpty);
    // 300 sequential pushes should complete quickly (no retry delays).
    expect(sw.elapsed, lessThan(const Duration(seconds: 30)));
  });

  testWidgets('performance: queue retries with backoff then recovers',
      (tester) async {
    var calls = 0;
    final manager = SyncManager(
      push: (e) async {
        calls++;
        // Fail twice (offline), then the network recovers.
        return calls <= 2 ? SyncResult.failure : SyncResult.success;
      },
    );
    manager.enqueue(SyncQueueEntry(
      id: 'q1',
      entityType: 'rep',
      entityId: 'r1',
      action: SyncAction.create,
      createdAt: DateTime.now(),
    ));
    await manager.processQueue();
    expect(calls, 3);
    expect(manager.pendingQueue, isEmpty);
    expect(manager.failedEntries, isEmpty);
  });
}