/// A single counted rep within a [WorkoutSession] (many-to-one).
class RepRecord {
 final String id;
 final String sessionId;
 final DateTime timestamp;
 final Map<String, int> phaseDurations;
 final double formScore;
 final String? feedbackMessage;
 final String? landmarksJson;

 const RepRecord({
 required this.id,
 required this.sessionId,
 required this.timestamp,
 this.phaseDurations = const {},
 this.formScore = 0,
 this.feedbackMessage,
 this.landmarksJson,
 });

 RepRecord copyWith({
 String? id,
 String? sessionId,
 DateTime? timestamp,
 Map<String, int>? phaseDurations,
 double? formScore,
 String? feedbackMessage,
 String? landmarksJson,
 }) =>
 RepRecord(
 id: id ?? this.id,
 sessionId: sessionId ?? this.sessionId,
 timestamp: timestamp ?? this.timestamp,
 phaseDurations: phaseDurations ?? this.phaseDurations,
 formScore: formScore ?? this.formScore,
 feedbackMessage: feedbackMessage ?? this.feedbackMessage,
 landmarksJson: landmarksJson ?? this.landmarksJson,
 );

 factory RepRecord.fromJson(Map<String, dynamic> json) => RepRecord(
 id: json['id'] as String,
 sessionId: json['sessionId'] as String,
 timestamp: DateTime.parse(json['timestamp'] as String),
 phaseDurations: (json['phaseDurations'] as Map<String, dynamic>?)
 ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
 const {},
 formScore: (json['formScore'] as num?)?.toDouble() ?? 0,
 feedbackMessage: json['feedbackMessage'] as String?,
 landmarksJson: json['landmarksJson'] as String?,
 );

 Map<String, dynamic> toJson() => {
 'id': id,
 'sessionId': sessionId,
 'timestamp': timestamp.toIso8601String(),
 'phaseDurations': phaseDurations,
 'formScore': formScore,
 'feedbackMessage': feedbackMessage,
 'landmarksJson': landmarksJson,
 };
}