import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can add logging or minimal processing here if needed.
  debugPrint('📩 BG message: ${message.messageId}');
}

class ProfNotificationService {
  ProfNotificationService._();
  static final ProfNotificationService instance = ProfNotificationService._();

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'quiz_notifications', // id
    'Quiz Notifications', // name
    description: 'Notifications when students finish quizzes',
    importance: Importance.high,
  );

  /// Call once on app startup after Firebase.initializeApp
  static Future<void> initialize() async {
    // Create Android notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Request notification permissions (Android < 13 & iOS)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Always refresh/save FCM token on launch
    await _saveCurrentFcmToken();

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });

    // Subscribe professor app to quiz results topic
    await messaging.subscribeToTopic('quiz_results');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When app opened from terminated/background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 Notification opened: ${message.messageId}');
      // You can navigate to notifications screen here if needed.
    });

    // Handle the case where the app was launched by tapping on a notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '🚀 App launched from notification: ${initialMessage.messageId}');
    }
  }

  static Future<void> _saveCurrentFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('system')
          .doc('professor_app')
          .set(
        {
          'fcmToken': token,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      debugPrint('✅ Professor FCM token saved');
    } catch (e) {
      debugPrint('❌ Error saving professor FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;

    if (notification != null && android != null) {
      final title = notification.title ?? 'Quiz Result';
      final body = notification.body ?? 'A student has finished a quiz.';

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}
