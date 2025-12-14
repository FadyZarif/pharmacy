import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../enums/notification_type.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Firebase Project ID - Get from Firebase Console
  static const String _projectId = 'pharmacy-employee-system-new';

  // Service Account JSON - Get from Firebase Console -> Project Settings -> Service Accounts
  // Generate new private key and copy the JSON content here
  static const Map<String, dynamic> _serviceAccountJson = {
    "type": "service_account",
    "project_id": _projectId,
    "private_key_id": "d98e17de6bc5c80450ba3d82cef57d259621fba6",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDdFC9sQxaA/Lyz\npxB6CUIZn6camjbotL5tmrClMfcQI7+8oVqayS2B51UVB/nERtFZTs60hKR/EMp2\nH+s/ftXYrfw0BoUnrqU8vZB/MFCNIin22U7LrE+dKqfJzF4l5cc4mBNgf93VigLX\nk8eT27ypMhu4Ozv1LXCW+2DBxPhgcmYV2/O4uG8aJM5sRUZ0b7uh/QkDLL9a8yKQ\nDdG8YL9Z5STVYWMCP7qwQLsQhZzTmEtWeVuMko60uVmJSIqs2S4mzOllj0h+euKr\nJ77F8JqOaRefHNozxv9mVcMXJSq8uc4rox3TXJiWm12w70dEMRHdZp4haaQTDlGY\nwVqpGk8JAgMBAAECggEAFqs7MZ6vcAp6TvGSfvD0FiyItfGaL8JYxGRYOJgm/UCt\nKGpjH/wA7pEJ6F4o/jdEwCOUjm4Lb/wIxpP/S0N2KgGtGqiQfsEpsFC/wErz94TJ\nSMZ/jeLdRwBYtBiAjuJAy0zMr9hsprjAEdrVXBPsBG1e6kUooLtIEDM2eKf5z+m6\nQIjAPvk7Sm/HazEXZIqjwtICR7e1aKLxNgRi7ptxhypknAxCAEULZ3HklPEz5YMD\nnIsNSLQTGgOdSCmtJqK0rM8xQFdKNqwP15jbBkRgB67FEt5qU5gchvjNFPAlGvq3\n/nJRDITsoYcJyVTITbmPdN8Q2XrEqdxeGRbsWhNNAQKBgQDzzgAkYeslNwe/5WH8\nHYAu9Tv24VLnAHszUJXjIbCrpKknMroqFC1Qh7SGqt5xStVFAfHoAQBYnV/QLZQR\ntilWZXj8nqAXo/65msPq+aV++JItQQ+jZMMebg11fKNg91NwhcSBK/pN1pYsuJ5A\nE5H6eyHOssHenuK11Eoz3n8eFwKBgQDoIyw8wlOaNF40gkwHr9lKVV9aS4cPMogE\nPW06rkEjdMe7j7mVGbByN0d612nhhquD6LG+X6I3/hp6R+9k1mM4sB0kQvOqOfDw\n2TOTOM++enTn3eswBv+bhOEjoe1KkPzOD4iwM/TWsdyIHilYxUY1T24KOwNFRwa7\n3UO+hlpP3wKBgA2uu/dOv4GhKwAsAWnCxhTcknbyglKQhlmE5kSO+XlIjm2yvRvr\ncfeZBhqgsEcvafSrfUYF+F0AyAXI6Qxtarh8jWOwC1AIVh1YgDJJvG35yUpc4mHL\nH+AvUPYM/qZMexRPjY2qSCviJR9xZQA3mPOzwVv2UEcMJ7EIrvlmPUAVAoGAVra0\n0qmAk0zWl+TIQ+LTV2oWqWMnO20T1AmiINZw7K614YFpwKGNAM1XfTK0kZM9xJOK\nueN9dE8OUvlGGrPe8pEPAbmkzcTBFSb9lhQVvkB+JRMHxLQIjW6Qrz/QpRcN6Gdz\nFucBoaVlDM+/gDKI7GcUYuvyZ9GFWW3o3WXQnJ8CgYAo6p1yqn1pyhthSfpKZyJF\nUp9kv+OmR79IgblmZ5TeoYfsyHLxjtsK8RrsKYmmsdC81GE5wgSGPeKNxJ5l/uNI\nB9epEanJQA3ldRgk2rxjVWU/1jBAyVDuUGPOBKvx0226pyGaZAbWT59kSFnSiyBH\n5zYc+L9jbwdjaQBMDv+X6w==\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@pharmacy-employee-system-new.iam.gserviceaccount.com",
    "client_id": "116546796225599521238",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40pharmacy-employee-system-new.iam.gserviceaccount.com",
  };

  bool _initialized = false;
  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permissions (iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else {
        print('User declined notification permission');
        _initialized = true; // Mark as initialized anyway
        return;
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
      _initialized = true; // Continue without notifications
      return;
    }

    // Initialize local notifications
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'pharmacy_notifications',
        'Pharmacy Notifications',
        description: 'Notifications for pharmacy app',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing local notifications: $e');
      // Continue anyway
    }

    // Set up FCM (if available)
    try {
      // Set up foreground notification presentation options for iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen to background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification opened app from background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

      // Check if app was opened from a notification (when terminated)
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpened(initialMessage);
      }

      print('FCM handlers initialized successfully');
    } catch (e) {
      print('Error initializing FCM handlers: $e');
      print('App will work without push notifications');
      // Continue anyway - local notifications will still work
    }

    _initialized = true;
    print('NotificationService initialized');
  }

  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        print('FCM Token: $token');
        return token;
      } else {
        print('FCM Token is null - Google Play Services may not be available');
        return null;
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      print('This is normal on emulators without Google Play Services');
      return null;
    }
  }

  Future<void> updateUserToken(String userId) async {
    try {
      String? token = await getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        print('FCM token updated for user: $userId');
      } else {
        print('Cannot update FCM token - token is null or empty');
        print('User will not receive push notifications');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
      // Don't throw - app should continue even without notifications
    }
  }

  /// Get OAuth 2.0 access token using service account
  Future<String> _getAccessToken() async {
    // Check if we have a valid token
    if (_accessToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken!;
      }
    }

    try {
      // Create service account credentials
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        _serviceAccountJson,
      );

      // Define the required scopes
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // Obtain credentials
      final authClient = await auth.clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      // Get access token
      _accessToken = authClient.credentials.accessToken.data;
      _tokenExpiry = authClient.credentials.accessToken.expiry;

      authClient.close();

      return _accessToken!;
    } catch (e) {
      print('Error getting access token: $e');
      throw Exception('Failed to get access token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');

    // Show local notification when app is in foreground
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationOpened(RemoteMessage message) {
    print('Notification opened: ${message.data}');
    // TODO: Handle navigation based on notification type
    // This will be implemented with navigation logic
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      print('Notification tapped with payload: ${response.payload}');
      // TODO: Handle navigation based on payload
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pharmacy_notifications',
      'Pharmacy Notifications',
      channelDescription: 'Notifications for pharmacy app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Send notification to specific users by their FCM tokens
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    NotificationType? type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get FCM tokens for the users
      List<String> tokens = await _getFcmTokens(userIds);

      if (tokens.isEmpty) {
        print('No FCM tokens found for users');
        return;
      }

      // Prepare notification data
      Map<String, dynamic> data = {
        'type': type?.value ?? '',
        ...?additionalData,
      };

      // Send to each token
      for (String token in tokens) {
        await _sendToToken(
          token: token,
          title: title,
          body: body,
          data: data,
        );
      }

      print('Notifications sent to ${tokens.length} users');
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  Future<List<String>> _getFcmTokens(List<String> userIds) async {
    try {
      List<String> tokens = [];

      for (String userId in userIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          // Check if fcmToken field exists
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('fcmToken')) {
            String? token = data['fcmToken'] as String?;
            if (token != null && token.isNotEmpty) {
              tokens.add(token);
            }
          }
        }
      }

      return tokens;
    } catch (e) {
      print('Error getting FCM tokens: $e');
      return [];
    }
  }

  Future<void>  _sendToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get OAuth 2.0 access token
      final accessToken = await _getAccessToken();

      // Construct FCM API V1 endpoint
      final url = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      // Construct message payload for FCM API V1
      final message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data.map((key, value) => MapEntry(key, value.toString())),
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'pharmacy_notifications',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending notification to token: $e');
    }
  }

  /// Get users by role and branches for sending notifications
  Future<List<String>> getUserIdsByRoleAndBranches({
    required List<String> roles,
    List<String>? branchIds,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: roles)
          .where('isActive', isEqualTo: true);

      QuerySnapshot snapshot = await query.get();
      List<String> userIds = [];

      for (var doc in snapshot.docs) {
        if (branchIds != null && branchIds.isNotEmpty) {
          // Check if user has access to any of the specified branches
          List<dynamic> userBranches = doc.get('branches') as List<dynamic>;
          bool hasAccess = userBranches
              .any((branch) => branchIds.contains(branch['id']));

          if (hasAccess) {
            userIds.add(doc.id);
          }
        } else {
          userIds.add(doc.id);
        }
      }

      return userIds;
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}

