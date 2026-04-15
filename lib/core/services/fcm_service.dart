import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

// Platform check that works on web
bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
String get _platformName => kIsWeb ? 'web' : defaultTargetPlatform.name;

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message: ${message.messageId}');
}

/// Service for Firebase Cloud Messaging (Push Notifications)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  String? _currentUserId;
  String? _currentToken;

  /// Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sanad_chat_channel',
    'Chat Notifications',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
    } catch (e, st) {
      _logError('initialize.local_notifications', e, st);
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e, st) {
      _logError('initialize.background_handler', e, st);
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object error, StackTrace st) {
        _logError('initialize.foreground_listener', error, st);
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
      onError: (Object error, StackTrace st) {
        _logError('initialize.opened_app_listener', error, st);
      },
    );

    try {
      // On iOS, skip getInitialMessage if APNS token is not yet available
      // (e.g. on Simulator or before permissions are granted) to avoid
      // an indefinite hang that consumes the whole initialization budget.
      final canCheck = kIsWeb || _isAndroid || await _waitForApnsToken();
      if (canCheck) {
        final initialMessage = await _messaging.getInitialMessage().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
              'FCM: getInitialMessage timed out — skipping launch notification',
            );
            return null;
          },
        );
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } else {
        debugPrint(
          'FCM: Skipping getInitialMessage — APNS token not available',
        );
      }
    } catch (e, st) {
      _logError('initialize.initial_message', e, st);
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        _currentToken = token;
        if (_currentUserId != null) {
          try {
            await _saveTokenToFirestore(_currentUserId!, token);
          } catch (e, st) {
            _logError('initialize.token_refresh_save', e, st);
          }
        }
      },
      onError: (Object error, StackTrace st) {
        _logError('initialize.token_refresh_listener', error, st);
      },
    );
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (_isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_channel);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('FCM Permission: ${settings.authorizationStatus}');
    return granted;
  }

  /// Cached result so we don't retry multiple times in the same session.
  bool? _apnsTokenAvailable;

  /// Wait for APNS token on iOS before calling FCM getToken/subscribe.
  /// On iOS, the APNS token may not be available immediately after permission
  /// is granted. This method polls for it with a short retry loop.
  ///
  /// On the iOS Simulator, APNS tokens are never available (push notifications
  /// are not supported). The method returns quickly after a few attempts.
  Future<bool> _waitForApnsToken() async {
    // Only needed on iOS (not web, not Android)
    if (kIsWeb || _isAndroid) return true;

    // Return cached result if we already checked
    if (_apnsTokenAvailable != null) return _apnsTokenAvailable!;

    // Try a few times with short delays (max ~2s total)
    const maxRetries = 4;
    const delay = Duration(milliseconds: 500);

    for (var i = 0; i < maxRetries; i++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          debugPrint('FCM: APNS token available (attempt ${i + 1})');
          _apnsTokenAvailable = true;
          return true;
        }
      } catch (e) {
        debugPrint('FCM: APNS token check error (attempt ${i + 1}): $e');
      }
      if (i < maxRetries - 1) await Future.delayed(delay);
    }

    debugPrint(
      'FCM: APNS token not available after $maxRetries attempts '
      '(expected on Simulator — push notifications require a physical device)',
    );
    _apnsTokenAvailable = false;
    return false;
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      // On iOS, wait for APNS token before requesting FCM token
      final apnsReady = await _waitForApnsToken();
      if (!apnsReady) {
        debugPrint('FCM: Skipping getToken — APNS token not available');
        return null;
      }

      if (kIsWeb) {
        // On web, VAPID key is required for getToken()
        final vapidKey = AppConfig.fcmVapidKey;
        _currentToken = await _messaging.getToken(
          vapidKey: vapidKey.isNotEmpty ? vapidKey : null,
        );
      } else {
        _currentToken = await _messaging.getToken();
      }
      return _currentToken;
    } catch (e, st) {
      _logError('getToken', e, st);
      return null;
    }
  }

  /// Register user for notifications
  Future<void> registerUser(String userId) async {
    _currentUserId = userId;

    try {
      final token = await getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }
    } catch (e, st) {
      _logError('registerUser.save_token', e, st);
    }

    if (!kIsWeb) {
      try {
        // On iOS, APNS token must be ready before subscribing to topics
        final apnsReady = await _waitForApnsToken();
        if (apnsReady) {
          await _messaging.subscribeToTopic('user_$userId');
        } else {
          debugPrint(
            'FCM: Skipping topic subscription — APNS token not available',
          );
        }
      } catch (e, st) {
        _logError('registerUser.subscribe_topic', e, st);
      }
    }
  }

  /// Unregister user (on logout)
  Future<void> unregisterUser() async {
    final previousUserId = _currentUserId;
    final previousToken = _currentToken;

    if (previousUserId != null && previousToken != null) {
      try {
        await _removeTokenFromFirestore(previousUserId, previousToken);
      } catch (e, st) {
        _logError('unregisterUser.remove_token', e, st);
      }
      if (!kIsWeb) {
        try {
          await _messaging.unsubscribeFromTopic('user_$previousUserId');
        } catch (e, st) {
          _logError('unregisterUser.unsubscribe_topic', e, st);
        }
      }
    }
    _currentUserId = null;
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      final deviceInfo = _getDeviceInfo();
      final docRef = _firestore.collection('user_fcm_tokens').doc(userId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Check if token already exists
        final data = doc.data();
        final tokens =
            (data?['tokens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final existingToken = tokens.any((t) => t['token'] == token);

        if (!existingToken) {
          // Add new token to array
          await docRef.update({
            'tokens': FieldValue.arrayUnion([
              {
                'token': token,
                'platform': _platformName,
                'device_id': deviceInfo['deviceId'],
                'created_at': DateTime.now().toIso8601String(),
              },
            ]),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          // Token exists, just update the top-level timestamp to show the user is active
          await docRef.update({'updated_at': FieldValue.serverTimestamp()});
        }
      } else {
        // Create new document
        await docRef.set({
          'tokens': [
            {
              'token': token,
              'platform': _platformName,
              'device_id': deviceInfo['deviceId'],
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
          'notification_settings': {
            'chat_enabled': true,
            'booking_enabled': true,
            'community_enabled': true,
            'system_enabled': true,
          },
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('FCM Token saved for user: $userId');
    } catch (e, st) {
      _logError('saveTokenToFirestore', e, st);
      rethrow;
    }
  }

  /// Remove FCM token from Firestore
  Future<void> _removeTokenFromFirestore(String userId, String token) async {
    try {
      // Get current document
      final doc = await _firestore
          .collection('user_fcm_tokens')
          .doc(userId)
          .get();
      if (!doc.exists) return;

      final data = doc.data();
      final tokens =
          (data?['tokens'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      // Remove token from array
      tokens.removeWhere((t) => t['token'] == token);

      await _firestore.collection('user_fcm_tokens').doc(userId).update({
        'tokens': tokens,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM Token removed for user: $userId');
    } catch (e, st) {
      _logError('removeTokenFromFirestore', e, st);
      rethrow;
    }
  }

  /// Get device info
  Map<String, String> _getDeviceInfo() {
    // Simplified device info - in production use device_info_plus package
    return {
      'deviceId': '${_platformName}_${DateTime.now().millisecondsSinceEpoch}',
      'platform': _platformName,
    };
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM Foreground Message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // Don't show notification if user is in the same chat
    if (_shouldSuppressNotification(data)) {
      debugPrint('FCM: Suppressing notification - user is in chat');
      return;
    }

    // Show local notification
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New Message',
        body: notification.body ?? '',
        payload: data,
      );
    }
  }

  /// Check if notification should be suppressed
  bool _shouldSuppressNotification(Map<String, dynamic> data) {
    debugPrint('FCM Data payload: $data');
    if (data.containsKey('sender_id')) {
      final senderId = data['sender_id'];

      // If the sender is the current user, or if it's admin sending a message
      // and we are currently logged in as an admin
      if (senderId == _currentUserId || senderId == 'admin') {
        return true;
      }
    }

    // This would be set by the chat screen when active
    // For now, return false to always show
    return false;
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload != null ? _encodePayload(payload) : null,
      );
    } catch (e, st) {
      _logError('showLocalNotification', e, st);
    }
  }

  /// Encode payload to string
  String _encodePayload(Map<String, dynamic> payload) {
    return payload.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload from string
  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    final map = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final kv = part.split('=');
      if (kv.length == 2) {
        map[kv[0]] = kv[1];
      }
    }
    return map;
  }

  /// Handle notification tap (from background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM Notification Tapped: ${message.data}');
    _navigateFromNotification(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local Notification Tapped: ${response.payload}');
    final payload = _decodePayload(response.payload);
    _navigateFromNotification(payload);
  }

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Set navigator key for navigation
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final chatId = data['chatId'] as String? ?? data['chat_id'] as String?;
    final bookingId =
        data['bookingId'] as String? ?? data['booking_id'] as String?;
    final postId = data['postId'] as String? ?? data['post_id'] as String?;
    final actionRoute = data['action_route'] as String?;

    if (_navigatorKey?.currentState == null) {
      debugPrint('FCM Navigate Error: Navigator key not set');
      return;
    }

    debugPrint(
      'FCM Navigate: type=$type, chatId=$chatId, bookingId=$bookingId, postId=$postId, actionRoute=$actionRoute',
    );
    final context = _navigatorKey!.currentContext;
    if (context == null) {
      debugPrint('FCM Navigate Error: No context available');
      return;
    }

    // Use GoRouter to navigate
    try {
      final goRouter = GoRouter.of(context);

      // If action_route is provided, use it directly
      if (actionRoute != null && actionRoute.isNotEmpty) {
        debugPrint('Navigating to action route: $actionRoute');
        goRouter.push(actionRoute);
        return;
      }

      // Otherwise, use type-based navigation
      switch (type) {
        case 'support_chat_message':
        case FCMNotificationType.supportChat:
          // Navigate to support chat
          debugPrint('Navigating to support chat');
          goRouter.pushNamed('userSupportChat');
          break;

        case 'therapist_chat_message':
        case 'message':
        case FCMNotificationType.therapistChat:
          if (chatId != null) {
            debugPrint('Navigating to therapist chat: $chatId');
            goRouter.pushNamed(
              'userTherapistChat',
              pathParameters: {'chatId': chatId},
            );
          } else {
            // If no chatId, go to home (user can see their chats there)
            debugPrint('No chatId provided, navigating to home');
            goRouter.go('/');
          }
          break;

        case 'new_booking':
        case 'booking_status_changed':
        case 'booking':
        case FCMNotificationType.bookingUpdate:
        case FCMNotificationType.bookingReminder:
          // Navigate to bookings screen (no specific booking detail route for users)
          debugPrint('Navigating to bookings screen');
          goRouter.push('/bookings');
          break;

        case 'community':
        case FCMNotificationType.communityPost:
          // Navigate to community screen (no specific post detail route)
          debugPrint('Navigating to community');
          goRouter.go('/community');
          break;

        case 'system_announcement':
        case FCMNotificationType.systemAnnouncement:
          // Go to notifications screen
          debugPrint('Navigating to notifications');
          goRouter.pushNamed('notifications');
          break;

        case 'therapist':
          // Navigate to therapists list
          debugPrint('Navigating to therapists');
          goRouter.go('/therapists');
          break;

        case 'mood':
          // Navigate to mood tracker
          debugPrint('Navigating to mood tracker');
          goRouter.pushNamed('moodTracker');
          break;

        case 'payment':
          // Navigate to subscription screen
          debugPrint('Navigating to subscription');
          goRouter.pushNamed('subscription');
          break;

        case 'crisis':
        case FCMNotificationType.crisis:
          // Navigate to crisis alerts screen (admin) or crisis response (user)
          debugPrint('Navigating to crisis alerts');
          goRouter.push('/admin/crisis-alerts');
          break;

        case 'handoff':
        case FCMNotificationType.handoff:
          // Navigate to hybrid chat or handoff management
          debugPrint('Navigating to hybrid chat');
          goRouter.push('/chat/hybrid');
          break;

        case 'call':
        case FCMNotificationType.call:
          // Navigate to call history
          debugPrint('Navigating to call history');
          goRouter.push('/call-history');
          break;

        default:
          debugPrint(
            'Unknown notification type: $type, going to notifications screen',
          );
          goRouter.pushNamed('notifications');
      }
    } catch (e) {
      debugPrint('FCM Navigation Error: $e');
      // Fallback: try to go to notifications screen
      try {
        GoRouter.of(context).pushNamed('notifications');
      } catch (_) {
        debugPrint('Failed to navigate to fallback route');
      }
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings({
    required String userId,
    bool? chatEnabled,
    bool? bookingEnabled,
    bool? communityEnabled,
    bool? systemEnabled,
  }) async {
    final updates = <String, dynamic>{};

    if (chatEnabled != null) {
      updates['notification_settings.chat_enabled'] = chatEnabled;
    }
    if (bookingEnabled != null) {
      updates['notification_settings.booking_enabled'] = bookingEnabled;
    }
    if (communityEnabled != null) {
      updates['notification_settings.community_enabled'] = communityEnabled;
    }
    if (systemEnabled != null) {
      updates['notification_settings.system_enabled'] = systemEnabled;
    }

    if (updates.isEmpty) {
      return true;
    }

    try {
      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('user_fcm_tokens')
          .doc(userId)
          .update(updates);
      return true;
    } catch (e, st) {
      _logError('updateNotificationSettings', e, st);
      return false;
    }
  }

  /// Get notification settings for user
  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_fcm_tokens')
          .doc(userId)
          .get();
      if (!doc.exists) {
        return {
          'chat_enabled': true,
          'booking_enabled': true,
          'community_enabled': true,
          'system_enabled': true,
        };
      }

      final settings =
          doc.data()?['notification_settings'] as Map<String, dynamic>?;
      return {
        'chat_enabled': settings?['chat_enabled'] as bool? ?? true,
        'booking_enabled': settings?['booking_enabled'] as bool? ?? true,
        'community_enabled': settings?['community_enabled'] as bool? ?? true,
        'system_enabled': settings?['system_enabled'] as bool? ?? true,
      };
    } catch (e, st) {
      _logError('getNotificationSettings', e, st);
      return {
        'chat_enabled': true,
        'booking_enabled': true,
        'community_enabled': true,
        'system_enabled': true,
      };
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e, st) {
      _logError('clearAllNotifications', e, st);
    }
  }

  void _logError(String phase, Object error, StackTrace stackTrace) {
    debugPrint('FCM Error [$phase]: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  /// Dispose service
  void dispose() {
    _foregroundSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}

/// FCM Notification types
class FCMNotificationType {
  static const String supportChat = 'support_chat';
  static const String therapistChat = 'therapist_chat';
  static const String bookingUpdate = 'booking_update';
  static const String bookingReminder = 'booking_reminder';
  static const String communityPost = 'community_post';
  static const String systemAnnouncement = 'system';
  static const String crisis = 'crisis';
  static const String handoff = 'handoff';
  static const String call = 'call';
}
