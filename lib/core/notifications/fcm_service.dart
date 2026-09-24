import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configures Firebase Messaging, registers (and refreshes) the device
/// token and manages topic subscriptions.
class FcmService {
 final FirebaseMessaging? _messagingOverride;
 final FlutterLocalNotificationsPlugin? _localNotificationsOverride;

 FlutterLocalNotificationsPlugin? _local;
 StreamSubscription<String>? _tokenSub;

 FcmService({FirebaseMessaging? messaging, FlutterLocalNotificationsPlugin? localNotifications})
 : _messagingOverride = messaging,
 _localNotificationsOverride = localNotifications;

 FirebaseMessaging get _messaging =>
 _messagingOverride ?? FirebaseMessaging.instance;

 /// Initializes Firebase (if needed), requests notification permission,
 /// sets up the foreground presentation and the local-notifications
 /// channel for background/foreground display.
 Future<void> initialize() async {
  await Firebase.initializeApp();

 await _messaging.requestPermission(
 alert: true, badge: true, sound: true);

 await FirebaseMessaging.instance
 .setForegroundNotificationPresentationOptions(
 alert: true, badge: true, sound: true);

 _local = _localNotificationsOverride ?? FlutterLocalNotificationsPlugin();
 await _local!.initialize(
 const InitializationSettings(
 android: AndroidInitializationSettings('@mipmap/ic_launcher'),
 iOS: DarwinInitializationSettings(),
 ),
 );
 await _local!
 .resolvePlatformSpecificImplementation<
 AndroidFlutterLocalNotificationsPlugin>()
 ?.createNotificationChannel(const AndroidNotificationChannel(
 'fitpact_channel', 'FitPact',
 description: 'Workout reminders and challenge updates',
 importance: Importance.high,
 ));

 _tokenSub = _messaging.onTokenRefresh.listen((token) {
 onTokenRefreshed?.call(token);
 });
 }

 /// Callback invoked whenever the FCM token is refreshed.
 void Function(String token)? onTokenRefreshed;

 /// Callback invoked when a message is shown while the app is in the
 /// foreground.
 void Function(RemoteMessage message)? onForegroundMessage;

 /// The current FCM registration token, or null if unavailable.
 Future<String?> getToken() => _messaging.getToken();

 /// Subscribes this device to a topic (e.g. per-challenge topics).
 Future<void> subscribeToTopic(String topic) =>
 _messaging.subscribeToTopic(topic);

 /// Unsubscribes this device from a topic.
 Future<void> unsubscribeFromTopic(String topic) =>
 _messaging.unsubscribeFromTopic(topic);

 /// Registers the foreground message handler.
 void listenForMessages() {
 FirebaseMessaging.onMessage.listen((message) {
 onForegroundMessage?.call(message);
 _showLocalNotification(message);
 });
 }

 Future<void> _showLocalNotification(RemoteMessage message) async {
 final notification = message.notification;
 if (notification == null || _local == null) return;
 await _local!.show(
 message.hashCode,
 notification.title,
 notification.body,
 const NotificationDetails(
 android: AndroidNotificationDetails(
   'fitpact_channel', 'FitPact',
   channelDescription:
   'Workout reminders and challenge updates',
   importance: Importance.high,
   priority: Priority.high,
 ),
 iOS: DarwinNotificationDetails(),
 ),
 payload: null,
 );
 }

 /// Background handler reference (must be a top-level function).
 @pragma('vm:entry-point')
 static Future<void> backgroundHandler(RemoteMessage message) async {
 // Background messages are handled by the OS tray; nothing to do here.
 }

 /// Disposes subscriptions.
 Future<void> dispose() async {
 await _tokenSub?.cancel();
 _tokenSub = null;
 }
}