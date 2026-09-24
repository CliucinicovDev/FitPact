/// Types of exercises supported by FitPact rep counting.
enum ExerciseType {
  /// Standard push-up.
  pushUp,

  /// Bodyweight squat.
  squat,

  /// Static plank hold.
  plank,

  /// Full burpee movement.
  burpee;

  /// Human-readable name for UI display.
  String get displayName {
    switch (this) {
      case ExerciseType.pushUp:
        return 'Push-Up';
      case ExerciseType.squat:
        return 'Squat';
      case ExerciseType.plank:
        return 'Plank';
      case ExerciseType.burpee:
        return 'Burpee';
    }
  }
}

/// Phases within a single rep movement.
enum ExercisePhase {
  /// Pre-rep preparation.
  setup,

  /// Descending (eccentric) portion.
  down,

  /// Static hold at the bottom.
  hold,

  /// Plank portion of a burpee.
  plank,

  /// Explosive jump portion of a burpee.
  jump,

  /// Ascending (concentric) portion.
  up,

  /// Rest between reps.
  recovery;

  /// Human-readable name for UI display.
  String get displayName {
    switch (this) {
      case ExercisePhase.setup:
        return 'Setup';
      case ExercisePhase.down:
        return 'Down';
      case ExercisePhase.hold:
        return 'Hold';
      case ExercisePhase.plank:
        return 'Plank';
      case ExercisePhase.jump:
        return 'Jump';
      case ExercisePhase.up:
        return 'Up';
      case ExercisePhase.recovery:
        return 'Recovery';
    }
  }
}

/// Quality assessment of a counted rep.
enum RepQuality {
  /// Flawless form.
  perfect,

  /// Minor form issues.
  good,

  /// Noticeable form issues.
  poor,

  /// Rep does not count.
  invalid;

  /// Human-readable name for UI display.
  String get displayName {
    switch (this) {
      case RepQuality.perfect:
        return 'Perfect';
      case RepQuality.good:
        return 'Good';
      case RepQuality.poor:
        return 'Poor';
      case RepQuality.invalid:
        return 'Invalid';
    }
  }

  /// Normalized score contribution of the rep (0.0 - 1.0).
  double get score {
    switch (this) {
      case RepQuality.perfect:
        return 1.0;
      case RepQuality.good:
        return 0.8;
      case RepQuality.poor:
        return 0.5;
      case RepQuality.invalid:
        return 0.0;
    }
  }
}

/// Cloud sync state of a workout session.
enum SyncStatus {
  /// Not yet uploaded.
  pending,

  /// Upload in progress.
  syncing,

  /// Successfully uploaded.
  synced,

  /// Upload failed.
  failed,

  /// Local/remote divergence needs resolution.
  conflict;

  /// Human-readable name for UI display.
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }
}

/// Physical orientation of the device during exercise.
enum DeviceOrientation {
  /// Portrait, top up.
  portrait,

  /// Portrait, top down.
  portraitUpsideDown,

  /// Landscape, left side up.
  landscapeLeft,

  /// Landscape, right side up.
  landscapeRight;

  /// Human-readable name for UI display.
  String get displayName {
    switch (this) {
      case DeviceOrientation.portrait:
        return 'Portrait';
      case DeviceOrientation.portraitUpsideDown:
        return 'Portrait (Upside Down)';
      case DeviceOrientation.landscapeLeft:
        return 'Landscape Left';
      case DeviceOrientation.landscapeRight:
        return 'Landscape Right';
    }
  }
}