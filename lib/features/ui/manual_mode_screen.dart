import 'dart:async';

import 'package:flutter/material.dart';

/// Manual rep counting screen: a big "+1 Rep" button, a session timer,
/// undo/reset actions and simple visual validation feedback.
class ManualModeScreen extends StatefulWidget {
  /// Title shown in the AppBar.
  final String title;

  /// Maximum reps per manual set (validation).
  final int maxReps;

  /// Callback invoked when the workout is finished.
  final void Function(int repCount, Duration duration)? onFinish;

  /// Creates the screen.
  const ManualModeScreen({
    super.key,
    this.title = 'Manual Mode',
    this.maxReps = 200,
    this.onFinish,
  });

  @override
  State<ManualModeScreen> createState() => _ManualModeScreenState();
}

class _ManualModeScreenState extends State<ManualModeScreen> {
  int _repCount = 0;
  final List<DateTime> _repTimes = [];
  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.green;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
  }

  void _addRep() {
    if (_repCount >= widget.maxReps) {
      setState(() {
        _feedbackMessage = 'Maximum reps reached';
        _feedbackColor = Colors.red;
      });
      return;
    }
    _startTimer();
    setState(() {
      _repCount++;
      _repTimes.add(DateTime.now());
      _feedbackMessage = 'Rep $_repCount counted';
      _feedbackColor = Colors.green;
    });
  }

  void _undoRep() {
    if (_repTimes.isEmpty) {
      setState(() {
        _feedbackMessage = 'Nothing to undo';
        _feedbackColor = Colors.orange;
      });
      return;
    }
    setState(() {
      _repTimes.removeLast();
      _repCount--;
      _feedbackMessage = 'Rep removed';
      _feedbackColor = Colors.orange;
    });
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _repCount = 0;
      _repTimes.clear();
      _startTime = null;
      _elapsed = Duration.zero;
      _feedbackMessage = null;
    });
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    widget.onFinish?.call(_repCount, _elapsed);
    if (mounted) {
      setState(() => _feedbackMessage = 'Workout finished: $_repCount reps');
    }
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_repCount',
              style: const TextStyle(
                  fontSize: 96, fontWeight: FontWeight.bold),
            ),
            Text('reps - ${_formatDuration(_elapsed)}',
                style: const TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              height: 180,
              child: FilledButton(
                onPressed: _addRep,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                ),
                child: const Text('+1 Rep',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _undoRep,
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _repCount > 0 ? _finish : null,
              child: const Text('Finish'),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 24),
              Text(
                _feedbackMessage!,
                style: TextStyle(color: _feedbackColor, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}