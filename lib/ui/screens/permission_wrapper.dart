import 'package:flutter/material.dart';
import 'package:messenger_app/services/notification_service.dart';
import 'package:messenger_app/ui/screens/auth_wrapper.dart';

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({Key? key}) : super(key: key);

  @override
  _PermissionWrapperState createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _permissionChecked = false;
  bool _showPermissionScreen = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check if notification permission is already granted
    final hasPermission = await NotificationService.areNotificationsEnabled();

    setState(() {
      _permissionChecked = true;
      _showPermissionScreen = !hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.requestNotificationPermissions(
      context,
    );

    if (mounted) {
      setState(() {
        _showPermissionScreen = !granted;
      });

      if (!granted) {
        // Show a message that they can enable it later
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can enable notifications later in the app settings',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      // Show loading screen while checking permissions
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Setting up your Just Chat...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_showPermissionScreen) {
      // Show permission request screen
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active, size: 80, color: Colors.blue),
                SizedBox(height: 32),
                Text(
                  'Stay Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Enable notifications to get instant alerts when you receive new messages from your friends.',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Enable Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showPermissionScreen = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Maybe Later', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'You can always enable notifications later in the app settings.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Permission handled, show main app
    return AuthWrapper();
  }
}
