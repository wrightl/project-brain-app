import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/routing/app_router.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/models/push_notification_data.dart';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Top-level function to handle background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handlers run in a separate isolate, so Firebase must be
  // initialized here before any Firebase API is used.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    // Without a logger isolate we keep this minimal; avoid throwing.
    return;
  }
  logInfo(
      '[PushNotification] Background message received: ${message.messageId}');
  // Handle background message here if needed
}

/// Service for managing push notifications via FCM
class PushNotificationService {
  final HttpService httpService;
  final AuthService authService;
  final SharedPreferences sharedPreferences;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _tokenStorageKey = 'fcm_token';
  static const String _deviceIdStorageKey = 'device_id';

  PushNotificationService({
    required this.httpService,
    required this.authService,
    required this.sharedPreferences,
  });

  /// Initialize push notification service.
  ///
  /// This performs non-blocking setup first. Permission prompts are optional
  /// and should generally be triggered by explicit user intent.
  Future<void> init({bool requestPermissionsOnInit = false}) async {
    try {
      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Set up message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);

      if (requestPermissionsOnInit) {
        await ensurePermissionsAndConfigure();
      }

      logInfo('[PushNotification] Service initialized');
    } catch (e, stackTrace) {
      logError('[PushNotification] Error initializing service', e, stackTrace);
    }
  }

  /// Request notification permission and apply platform presentation settings.
  ///
  /// Returns true when permissions are granted (or effectively granted).
  Future<bool> ensurePermissionsAndConfigure() async {
    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      logWarning('[PushNotification] Permissions not granted');
      return false;
    }

    await _configureNotificationSettings();
    return true;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
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
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Configure notification settings for iOS
  Future<void> _configureNotificationSettings() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        final granted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;

        logInfo(
            '[PushNotification] iOS permission status: ${settings.authorizationStatus}');
        return granted;
      } else if (Platform.isAndroid) {
        // Android 13+ (API 33+) requires runtime permission
        // Check version using a different approach since Platform.version is not available
        try {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            final requested = await Permission.notification.request();
            logInfo('[PushNotification] Android permission status: $requested');
            return requested.isGranted;
          }
          logInfo('[PushNotification] Android permission status: $status');
          return status.isGranted;
        } catch (e) {
          // If permission handler fails, assume granted (for older Android versions)
          logWarning(
              '[PushNotification] Error checking Android permission: $e');
          return true;
        }
      }
      return false;
    } catch (e, stackTrace) {
      logError(
          '[PushNotification] Error requesting permissions', e, stackTrace);
      return false;
    }
  }

  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logInfo(
          '[PushNotification] Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logInfo(
          '[PushNotification] Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        logInfo(
            '[PushNotification] App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Data-only goals sync: no notification, just refresh goals
      if (message.data['type'] == 'goals_updated') {
        sl<EggGoalsProvider>().syncFromAPI();
        return;
      }

      final notification = message.notification;
      if (notification == null) return;

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: notificationDetails,
        payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
      );
    } catch (e, stackTrace) {
      logError('[PushNotification] Error showing foreground notification', e,
          stackTrace);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final message = RemoteMessage(
          notification: null,
          data: data,
        );
        _handleNotificationTap(message);
      } catch (e) {
        logError('[PushNotification] Error parsing notification payload', e);
      }
    }
  }

  /// Handle notification tap and navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final notificationData = PushNotificationData(
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data.isNotEmpty ? message.data : null,
      );

      // Navigate based on notification data
      _navigateFromNotification(notificationData);
    } catch (e, stackTrace) {
      logError(
          '[PushNotification] Error handling notification tap', e, stackTrace);
    }
  }

  /// Navigate to appropriate screen based on notification data
  void _navigateFromNotification(PushNotificationData data) {
    logInfo('[PushNotification] Navigate from notification: type=${data.type}');

    // Store notification data for navigation handling
    if (data.data != null) {
      sharedPreferences.setString(
        'pending_notification',
        jsonEncode(data.data),
      );

      // Try to navigate immediately if router is available
      // This works when app is in foreground or background
      try {
        final router = sl<AppRouter>();
        router.navigateFromNotification(data.data!);
      } catch (e) {
        // Router might not be ready yet, data is stored for later
        logDebug(
            '[PushNotification] Router not ready, notification stored for later');
      }
    }
  }

  /// Get or generate device ID
  Future<String> _getDeviceId() async {
    String? deviceId = sharedPreferences.getString(_deviceIdStorageKey);
    if (deviceId == null || deviceId.isEmpty) {
      // Generate a simple device ID (in production, you might want to use device_info_plus)
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await sharedPreferences.setString(_deviceIdStorageKey, deviceId);
    }
    return deviceId;
  }

  /// Register FCM token with backend
  Future<bool> registerToken() async {
    try {
      // Check if user is authenticated
      if (!authService.isLoggedIn) {
        logWarning(
            '[PushNotification] Cannot register token: user not authenticated');
        return false;
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        logWarning('[PushNotification] Failed to get FCM token');
        return false;
      }

      // Get device ID
      final deviceId = await _getDeviceId();

      // Determine platform
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Register with backend
      final response = await httpService.post(
        '/push-notifications/register-token',
        body: jsonEncode({
          'token': token,
          'platform': platform,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        // Store token locally
        await sharedPreferences.setString(_tokenStorageKey, token);
        logInfo('[PushNotification] Token registered successfully');
        return true;
      } else {
        logError(
            '[PushNotification] Failed to register token: ${response.statusCode}',
            Exception(response.body));
        return false;
      }
    } catch (e, stackTrace) {
      logError('[PushNotification] Error registering token', e, stackTrace);
      return false;
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    logInfo('[PushNotification] Token refreshed');

    // Store new token
    await sharedPreferences.setString(_tokenStorageKey, newToken);

    // Re-register with backend if user is authenticated
    if (authService.isLoggedIn) {
      await registerToken();
    }
  }

  /// Unregister token from backend
  Future<bool> unregisterToken() async {
    try {
      final token = sharedPreferences.getString(_tokenStorageKey);
      if (token == null || token.isEmpty) {
        logWarning('[PushNotification] No token to unregister');
        return true; // Consider this a success since there's nothing to unregister
      }

      // Check if user is authenticated
      if (!authService.isLoggedIn) {
        logWarning(
            '[PushNotification] Cannot unregister token: user not authenticated');
        // Clear local token anyway
        await sharedPreferences.remove(_tokenStorageKey);
        return true;
      }

      // Unregister from backend. The token can contain reserved characters,
      // so URL-encode it; never log the raw token value.
      final response = await httpService.delete(
        '/push-notifications/remove-token?token=${Uri.encodeQueryComponent(token)}',
      );

      if (response.statusCode == 200) {
        // Clear local token
        await sharedPreferences.remove(_tokenStorageKey);
        logInfo('[PushNotification] Token unregistered successfully');
        return true;
      } else {
        logError(
            '[PushNotification] Failed to unregister token: ${response.statusCode}',
            Exception(response.body));
        // Clear local token anyway
        await sharedPreferences.remove(_tokenStorageKey);
        return false;
      }
    } catch (e, stackTrace) {
      logError('[PushNotification] Error unregistering token', e, stackTrace);
      // Clear local token on error
      await sharedPreferences.remove(_tokenStorageKey);
      return false;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e, stackTrace) {
      logError('[PushNotification] Error getting token', e, stackTrace);
      return null;
    }
  }

  /// Get stored token from local storage
  String? getStoredToken() {
    return sharedPreferences.getString(_tokenStorageKey);
  }

  /// Check if token is registered
  bool isTokenRegistered() {
    final token = getStoredToken();
    return token != null && token.isNotEmpty;
  }

  /// Get pending notification data (if app was opened from notification)
  Map<String, dynamic>? getPendingNotification() {
    final data = sharedPreferences.getString('pending_notification');
    if (data != null && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        // Clear after reading
        sharedPreferences.remove('pending_notification');
        return decoded;
      } catch (e) {
        logError('[PushNotification] Error parsing pending notification', e);
        sharedPreferences.remove('pending_notification');
        return null;
      }
    }
    return null;
  }
}
