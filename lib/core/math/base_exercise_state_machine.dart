import 'package:fitpact/core/enums/exercise_enums.dart';

/// A single recorded phase change within a state machine.
class PhaseTransition {
  /// Phase the machine was in before the change.
  final ExercisePhase from;

  /// Phase the machine moved to.
  final ExercisePhase to;

  /// Wall-clock time at which the transition occurred.
  final DateTime timestamp;

  /// Creates a transition record.
  const PhaseTransition({
    required this.from,
    required this.to,
    required this.timestamp,
  });
}

/// Base class for exercise-specific phase state machines.
///
/// Subclasses declare which phase changes are legal by overriding
/// [allowedTransitions]. The base class tracks the current phase and a
/// history of every accepted transition.
abstract class BaseExerciseStateMachine {
  /// Phases each phase may legally move to.
  Map<ExercisePhase, Set<ExercisePhase>> get allowedTransitions;

  ExercisePhase _phase = ExercisePhase.setup;
  final List<PhaseTransition> _history = [];

  /// The current phase of the movement.
  ExercisePhase get phase => _phase;

  /// All transitions accepted so far, in chronological order.
  List<PhaseTransition> get history => List.unmodifiable(_history);

  /// Whether transitioning from the current phase to [phase] is allowed.
  bool canTransitionTo(ExercisePhase phase) =>
      (allowedTransitions[_phase] ?? const <ExercisePhase>{}).contains(phase);

  /// Attempts to move to [phase].
  ///
  /// Returns the new phase on success, or `null` if the transition is not
  /// allowed (in which case the current phase and history are unchanged).
  ExercisePhase? transition(ExercisePhase phase) {
    if (!canTransitionTo(phase)) return null;
    _history.add(PhaseTransition(
      from: _phase,
      to: phase,
      timestamp: DateTime.now(),
    ));
    _phase = phase;
    return _phase;
  }

  /// Resets the machine to [ExercisePhase.setup] and clears the history.
  void reset() {
    _phase = ExercisePhase.setup;
    _history.clear();
  }
}