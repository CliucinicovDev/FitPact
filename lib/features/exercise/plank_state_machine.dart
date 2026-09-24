import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/math/base_exercise_state_machine.dart';

/// Phase state machine for a static plank hold.
///
/// Phases: setup -> hold -> recovery. While in hold, a timer tracks the
/// duration of the hold. The machine detects "hip sag" (or lift) by
/// comparing the shoulder-hip-knee angle: a deviation of more than
/// [sagAngleThreshold] degrees from a straight line ends the hold.
class PlankStateMachine extends BaseExerciseStateMachine {
  /// Maximum deviation (degrees) of the shoulder-hip-knee angle from
  /// 180 (straight line) before the hold is considered broken.
  final double sagAngleThreshold;

  /// Minimum hold duration (seconds) for a valid attempt.
  final double minHoldSeconds;

  DateTime? _holdStart;
  Duration _holdDuration = Duration.zero;
  Timer? _timer;
  bool _sagDetected = false;
  String? _lastWarning;

  PlankStateMachine({
    this.sagAngleThreshold = 15,
    this.minHoldSeconds = 0,
  });

  /// Duration of the current (or last completed) hold.
  Duration get holdDuration => _holdDuration;

  /// Whether hip sag was detected during the hold.
  bool get sagDetected => _sagDetected;

  /// Warning from the last invalid reset, if any.
  String? get lastWarning => _lastWarning;

  /// Wall-clock time the current hold started, if holding.
  DateTime? get holdStart => _holdStart;

  @override
  Map<ExercisePhase, Set<ExercisePhase>> get allowedTransitions => const {
        ExercisePhase.setup: {ExercisePhase.hold, ExercisePhase.recovery},
        ExercisePhase.hold: {ExercisePhase.recovery},
        ExercisePhase.recovery: {ExercisePhase.setup},
        ExercisePhase.down: {},
        ExercisePhase.up: {},
        ExercisePhase.plank: {},
        ExercisePhase.jump: {},
      };

  /// Starts the hold; call when the athlete enters plank position.
  ///
  /// Returns true if the transition to hold succeeded.
  bool startHold() {
    if (phase != ExercisePhase.setup) return false;
    if (transition(ExercisePhase.hold) == null) return false;
    _holdStart = clock.now();
    _holdDuration = Duration.zero;
    _sagDetected = false;
    _startTimer();
    return true;
  }

  /// Processes a new body-line angle sample (shoulder-hip-knee, degrees).
  ///
  /// While holding, an angle deviating more than [sagAngleThreshold] from
  /// 180 degrees breaks the hold and resets the machine with a warning.
  /// Returns the new phase, or null if no phase change occurred.
  ExercisePhase? processBodyAngle(double angle) {
    if (phase != ExercisePhase.hold) return null;
    final deviation = (180 - angle).abs();
    if (deviation > sagAngleThreshold) {
      _stopTimer();
      _resetWithWarning('Hip deviation detected (${deviation.round()}\u00B0)');
      _sagDetected = true;
      return ExercisePhase.setup;
    }
    return null;
  }

  /// Ends the hold and moves to recovery.
  ///
  /// Returns the hold duration, or null if not holding.
  Duration? endHold() {
    if (phase != ExercisePhase.hold) return null;
    _stopTimer();
    transition(ExercisePhase.recovery);
    return _holdDuration;
  }

  /// Updates [holdDuration] to the elapsed time since the hold started.
  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_holdStart != null) {
      _holdDuration = clock.now().difference(_holdStart!);
      }
    });
  }

  void _stopTimer() {
    if (_holdStart != null) {
      _holdDuration = clock.now().difference(_holdStart!);
    }
    _timer?.cancel();
    _timer = null;
  }

  /// Frees the timer. Call when the widget using this machine is disposed.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Resets the machine to setup and clears hold state.
  @override
  void reset() {
    _stopTimer();
    super.reset();
    _holdStart = null;
    _holdDuration = Duration.zero;
    _sagDetected = false;
    _lastWarning = null;
  }

  void _resetWithWarning(String message) {
    reset();
    _lastWarning = message;
  }
}