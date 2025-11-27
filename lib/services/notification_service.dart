import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // App-level notification preference key
  static const String _notificationEnabledKey = 'notifications_enabled';

  // Initialize notifications (Spark plan compatible - local only)
  static Future<void> initialize() async {
    // Initialize local notifications only
    await _initializeLocalNotifications();

    // Request notification permissions
    await _requestNotificationPermissions();

    // Start listening for new messages when user is authenticated
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startMessageListener();
      }
    });
  }

  // Request notification permissions
  static Future<bool> _requestNotificationPermissions() async {
    // For Android 13+ (API 33+), we need to request POST_NOTIFICATIONS permission
    final status = await Permission.notification.status;

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  // Check if notifications are enabled (both system and app level)
  static Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    final appEnabled = await getAppNotificationEnabled();
    return status.isGranted && appEnabled;
  }

  // Check system-level notification permission only
  static Future<bool> hasSystemPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Get app-level notification preference
  static Future<bool> getAppNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true; // Default to enabled
  }

  // Set app-level notification preference
  static Future<void> setAppNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
  }

  // Request permissions with user-friendly dialog
  static Future<bool> requestNotificationPermissions(
    BuildContext context,
  ) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Show explanation dialog first
      final shouldRequest = await _showPermissionDialog(context);
      if (!shouldRequest) return false;

      final result = await Permission.notification.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to go to settings
      await _showSettingsDialog(context);
      return false;
    }

    return false;
  }

  // Show permission explanation dialog
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Enable Notifications'),
              content: Text(
                'This app needs notification permission to alert you when you receive new messages. '
                'You can always change this in your device settings later.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Show settings dialog for permanently denied permissions
  static Future<void> _showSettingsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Permission Required'),
          content: Text(
            'Notifications are currently disabled. To receive message alerts, '
            'please enable notifications in your device settings.\n\n'
            'Go to: Settings > Apps > Messenger App > Notifications',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/logo');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateToChat(data);
    }
  }

  // Start listening for new messages in user's chats
  static void _startMessageListener() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Listen to all chats where user is a participant
    _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .listen((chatSnapshot) {
          for (var chatDoc in chatSnapshot.docs) {
            final chatId = chatDoc.id;

            // Listen to new messages in each chat
            _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .listen((messageSnapshot) {
                  if (messageSnapshot.docs.isNotEmpty) {
                    final latestMessage = messageSnapshot.docs.first;
                    final messageData = latestMessage.data();

                    // Only show notification if message is from someone else
                    if (messageData['senderId'] != currentUser.uid) {
                      _showMessageNotification(messageData, chatDoc.data());
                    }
                  }
                });
          }
        });
  }

  // Show local notification for new message
  static Future<void> _showMessageNotification(
    Map<String, dynamic> messageData,
    Map<String, dynamic> chatData,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Check if notifications are enabled (both system and app level)
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    // Get sender name
    final senderName = messageData['senderName'] ?? 'Someone';
    final messageText = messageData['text'] ?? 'New message';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'messages_channel',
          'Messages',
          channelDescription: 'Notifications for new messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/logo',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Create payload with chat info
    final payload = jsonEncode({
      'type': 'message',
      'senderId': messageData['senderId'],
      'senderName': senderName,
      'chatId': chatData['chatId'] ?? '',
    });

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      senderName,
      messageText,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Navigate to chat (placeholder for now)
  static void _navigateToChat(Map<String, dynamic> data) {
    // TODO: Implement navigation to specific chat
    // You can use a global navigator key or a navigation service
    print('Navigate to chat with data: $data');
  }

  // Send local notification (for testing) - with permission check
  static Future<bool> showTestNotification() async {
    // Check if notifications are enabled
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) {
      return false; // Return false to indicate permission issue
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      0,
      'Test Notification',
      'This is a test notification from your Just Chat app!',
      platformChannelSpecifics,
    );

    return true; // Return true to indicate success
  }

  // Show notification for specific message (can be called manually)
  static Future<void> showNotificationForMessage({
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'messages_channel',
          'Messages',
          channelDescription: 'Notifications for new messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/logo',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final payload = jsonEncode({
      'type': 'message',
      'senderName': senderName,
      'chatId': chatId ?? '',
    });

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      senderName,
      message,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
