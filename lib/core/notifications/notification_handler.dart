import 'package:fitpact/core/routing/deep_link_handler.dart';

/// The six FitPact notification types.
enum NotificationType {
  reminder,
  streak,
  lastLife,
  memberDropped,
  challengeDone,
  dispute;

  /// Parses the `type` field of a push payload; null when unknown.
  static NotificationType? fromName(String? name) {
    if (name == null) return null;
    for (final t in NotificationType.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// A parsed notification ready for display or routing.
class AppNotification {
 final NotificationType type;
 final String? title;
 final String? body;
 final Map<String, dynamic> data;

 const AppNotification({
 required this.type,
 this.title,
 this.body,
 this.data = const {},
 });

 factory AppNotification.fromPayload(Map<String, dynamic> payload) {
 final type = NotificationType.fromName(payload['type'] as String?) ??
 NotificationType.reminder;
 return AppNotification(
 type: type,
 title: payload['title'] as String?,
 body: payload['body'] as String?,
 data: (payload['data'] as Map?)?.cast<String, dynamic>() ?? const {},
 );
 }
}

/// Classifies incoming notifications and routes them via deep links.
class NotificationHandler {
 final DeepLinkHandler router;

 NotificationHandler(this.router);

 /// Handles a raw push payload: parses it and navigates to the
 /// screen matching its type (fallback: home).
 void handlePayload(Map<String, dynamic> payload) {
 final notification = AppNotification.fromPayload(payload);
 handle(notification);
 }

 /// Routes [notification] to the appropriate screen.
 void handle(AppNotification notification) {
 final path = routeFor(notification);
 router.navigate(path);
 }

 /// Maps a notification to its route path.
 static String routeFor(AppNotification notification) {
 switch (notification.type) {
 case NotificationType.reminder:
 return DeepLinkHandler.homeRoute;
 case NotificationType.streak:
 return DeepLinkHandler.streakRoute;
 case NotificationType.lastLife:
 case NotificationType.memberDropped:
 case NotificationType.challengeDone:
 case NotificationType.dispute:
 final challengeId = notification.data['challengeId'] as String?;
 if (challengeId == null) return DeepLinkHandler.homeRoute;
 if (notification.type == NotificationType.dispute) {
 return '${DeepLinkHandler.disputeRoutePrefix}/$challengeId';
 }
 return '${DeepLinkHandler.challengeRoutePrefix}/$challengeId';
 }
 }
}