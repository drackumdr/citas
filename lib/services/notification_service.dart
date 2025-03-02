import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Configure Firebase Messaging
    if (!kIsWeb) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap
    });

    // Save FCM token to Firestore for the current user
    _saveTokenToFirestore();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message ${message.messageId}');
  }

  static void _handleMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    // ignore: unused_local_variable
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medical_appointments_channel',
            'Medical Appointments',
            channelDescription: 'Notifications for medical appointments',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data['route'],
      );
    }
  }

  static Future<void> _saveTokenToFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await _firebaseMessaging.getToken();

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });
    }
  }

  static Future<void> sendAppointmentReminder({
    required String userId,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    // This would typically be done with a Cloud Function
    // This is just a placeholder for the client-side representation
    print(
        'Sending appointment reminder to $userId for appointment with $doctorName at $appointmentTime on $appointmentDate');

    // In a real implementation, you would call an HTTP endpoint or Cloud Function that would:
    // 1. Get the user's FCM token from Firestore
    // 2. Send an FCM message to that token
    // 3. Possibly also send WhatsApp/SMS via Twilio API
  }
}
