import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:flutter/material.dart';

/// Big centered rep counter with a pop animation on increment and a
/// small current-phase indicator underneath.
class RepCounterOverlay extends StatefulWidget {
  /// Current rep count.
  final int repCount;

  /// Current exercise phase, shown below the counter.
  final ExercisePhase phase;

  /// Creates the overlay.
  const RepCounterOverlay({
    super.key,
    required this.repCount,
    required this.phase,
  });

  @override
  State<RepCounterOverlay> createState() => _RepCounterOverlayState();
}

class _RepCounterOverlayState extends State<RepCounterOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant RepCounterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repCount > oldWidget.repCount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _scale,
            child: Text(
              '${widget.repCount}',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 12, color: Colors.black54),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Phase: ${widget.phase.displayName}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}