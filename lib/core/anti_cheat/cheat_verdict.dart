/// Shared result of all anti-cheat layers.
enum CheatVerdict {
  /// No anomaly detected.
  clean,

  /// Suspicious signals detected; needs further review.
  suspect,

  /// Not enough data to judge.
  invalid,
}

/// Result of a server-side (Layer 3) verification.
class Layer3Result {
  final CheatVerdict verdict;
  final String reason;

  const Layer3Result(this.verdict, this.reason);
}