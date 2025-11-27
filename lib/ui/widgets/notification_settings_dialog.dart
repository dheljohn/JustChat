import 'package:flutter/material.dart';
import 'package:messenger_app/services/notification_service.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({Key? key}) : super(key: key);

  @override
  _NotificationSettingsDialogState createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  bool _systemPermissionGranted = false;
  bool _appNotificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final systemPermission = await NotificationService.hasSystemPermission();
    final appEnabled = await NotificationService.getAppNotificationEnabled();
    
    if (mounted) {
      setState(() {
        _systemPermissionGranted = systemPermission;
        _appNotificationsEnabled = appEnabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleAppNotifications(bool value) async {
    if (!_systemPermissionGranted && value) {
      // Need to request system permission first
      final granted = await NotificationService.requestNotificationPermissions(context);
      if (granted) {
        await NotificationService.setAppNotificationEnabled(true);
        if (mounted) {
          setState(() {
            _systemPermissionGranted = true;
            _appNotificationsEnabled = true;
          });
        }
      }
    } else {
      // Just toggle app-level setting
      await NotificationService.setAppNotificationEnabled(value);
      if (mounted) {
        setState(() {
          _appNotificationsEnabled = value;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications, color: Colors.blue),
          SizedBox(width: 8),
          Text('Notification Settings'),
        ],
      ),
      content: _loading
          ? SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System Permission Status
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _systemPermissionGranted 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _systemPermissionGranted 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _systemPermissionGranted ? Icons.check_circle : Icons.cancel,
                        color: _systemPermissionGranted ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Permission',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _systemPermissionGranted ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              _systemPermissionGranted
                                  ? 'Granted'
                                  : 'Not granted',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_systemPermissionGranted)
                        TextButton(
                          onPressed: () async {
                            final granted = await NotificationService.requestNotificationPermissions(context);
                            if (granted && mounted) {
                              setState(() {
                                _systemPermissionGranted = true;
                              });
                            }
                          },
                          child: Text('Enable'),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // App-level notification toggle
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Get notified when you receive new messages',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _appNotificationsEnabled && _systemPermissionGranted,
                        onChanged: _systemPermissionGranted || !_appNotificationsEnabled
                            ? _toggleAppNotifications
                            : null,
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
                
                if (!_systemPermissionGranted)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'System permission is required to receive notifications. '
                      'Enable it above to use notification features.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        if (_systemPermissionGranted && _appNotificationsEnabled)
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await NotificationService.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Test notification sent!' 
                        : 'Failed to send notification'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Test'),
          ),
      ],
    );
  }
}