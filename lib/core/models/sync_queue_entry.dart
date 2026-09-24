/// An entry in the outbound sync queue.
class SyncQueueEntry {
  final String id;
  final String entityType;
  final String entityId;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final SyncEntryStatus status;
  final int retryCount;
  final DateTime createdAt;

  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payload = const {},
    this.status = SyncEntryStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
  });

  SyncQueueEntry copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncAction? action,
    Map<String, dynamic>? payload,
    SyncEntryStatus? status,
    int? retryCount,
    DateTime? createdAt,
  }) =>
      SyncQueueEntry(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
      );

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) =>
      SyncQueueEntry(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        action: SyncAction.values.byName(json['action'] as String),
        payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
        status: SyncEntryStatus.values.byName(
            (json['status'] as String?) ?? SyncEntryStatus.pending.name),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'action': action.name,
        'payload': payload,
        'status': status.name,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Queue entry action.
enum SyncAction { create, update, delete }

/// Queue entry status machine: pending -> syncing -> synced/failed.
enum SyncEntryStatus { pending, syncing, synced, failed }