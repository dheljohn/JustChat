# Notification System - Spark Plan Compatible

This messenger app includes a notification system that works with Firebase's free Spark plan by using only local notifications and Firestore listeners.

## How It Works

### 1. **Local Notifications Only**
- Uses `flutter_local_notifications` package
- No Firebase Cloud Messaging (FCM) required
- No Cloud Functions needed
- Works entirely on the client side

### 2. **Firestore Listeners**
- The app listens to Firestore changes in real-time
- When a new message arrives, it triggers a local notification
- Only shows notifications for messages from other users

### 3. **Features**
- ✅ Local notifications when app is in foreground
- ✅ Test notification functionality
- ✅ Notification tap handling (ready for navigation)
- ✅ Works on Android and iOS
- ✅ No server-side code required
- ✅ Free tier compatible

## Testing Notifications

### First Launch Experience
1. When you first install and run the app, you'll see a permission screen
2. Tap "Enable Notifications" to grant permission
3. Or tap "Maybe Later" to skip (you can enable later)

### Test Local Notifications
1. Go to the home screen
2. Tap the menu (⋮) in the top right
3. Select "Test Notification"
4. If permissions aren't granted, you'll be prompted to enable them
5. Once enabled, you should see a test notification appear

### Notification Settings Dialog
1. Go to home screen menu (⋮)
2. Select "Notification Settings"
3. View system permission status (granted/not granted)
4. Toggle app-level notifications on/off with the switch
5. Use "Test" button to verify notifications work
6. System permission can be enabled directly from the dialog

### Test Message Notifications
1. Create two user accounts
2. Send messages between them
3. When the app is open, you'll see notifications for incoming messages
4. The notification system automatically filters out your own messages

## Limitations (Spark Plan)

### What Works:
- Local notifications when app is running
- Real-time message detection via Firestore listeners
- Notification tap handling
- Test notifications
- Two-level notification control (system + app level)
- Toggle switch to enable/disable notifications within the app
- Persistent notification preferences

### What Doesn't Work (Requires Blaze Plan):
- Push notifications when app is completely closed
- Background message processing via Cloud Functions
- Cross-device notification synchronization
- Server-side notification logic

## Future Upgrades

If you upgrade to Firebase Blaze plan, you can:
1. Add Firebase Cloud Messaging back to pubspec.yaml
2. Deploy Cloud Functions for server-side notifications
3. Enable push notifications when app is closed
4. Add advanced notification features like message previews

## Files Modified

- `lib/services/notification_service.dart` - Main notification logic with permission handling
- `lib/services/chat_service.dart` - Simplified for local notifications
- `lib/services/auth_services.dart` - Removed FCM token handling
- `lib/ui/screens/permission_wrapper.dart` - New: First-launch permission screen
- `lib/ui/screens/home_screen.dart` - Added test notification and settings
- `lib/ui/widgets/notification_settings_dialog.dart` - New: Advanced settings dialog with toggle
- `lib/main.dart` - Updated to use permission wrapper
- `android/app/src/main/AndroidManifest.xml` - Added notification permissions
- `pubspec.yaml` - Uses permission_handler and shared_preferences

## Architecture

```
User sends message → Firestore → Real-time listener → Local notification
```

This approach ensures your messaging app has notification functionality while staying within Firebase's free tier limits.