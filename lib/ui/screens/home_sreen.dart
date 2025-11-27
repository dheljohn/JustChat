import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_app/ui/screens/compose_message_screen.dart';
import 'package:messenger_app/ui/screens/chat_screen.dart';
import 'package:messenger_app/services/chat_service.dart';
import 'package:messenger_app/services/notification_service.dart';
import 'package:messenger_app/ui/widgets/notification_settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildChatTile(Map<String, dynamic> chatData, String chatId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return SizedBox.shrink();

    final participants = List<String>.from(chatData['participants'] ?? []);
    final participantNames = Map<String, dynamic>.from(
      chatData['participantNames'] ?? {},
    );

    // Find the other user
    final otherUserId = participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return SizedBox.shrink();

    final otherUserName = participantNames[otherUserId] ?? 'Unknown';
    final lastMessage = chatData['lastMessage'] ?? '';
    final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
    final lastMessageSender = chatData['lastMessageSender'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[700],
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        otherUserName,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle:
          lastMessage.isNotEmpty
              ? Text(
                lastMessageSender == currentUser.uid
                    ? 'You: $lastMessage'
                    : lastMessage,
                style: TextStyle(color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              : Text(
                'No messages yet',
                style: TextStyle(color: Colors.grey[500]),
              ),
      trailing:
          lastMessageTime != null
              ? Text(
                _formatTime(lastMessageTime),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              )
              : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  chatId: chatId,
                  otherUserName: otherUserName,
                  otherUserAvatar: '', // TODO: Add avatar support
                  otherUserId: otherUserId,
                ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: Text('Just Chat', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          //Debugging
          // IconButton(
          //   icon: Icon(Icons.bug_report, color: Colors.white),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => FirestoreDebugScreen()),
          //     );
          //   },
          //   tooltip: 'Debug Firestore',
          // ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                try {
                  await FirebaseAuth.instance.signOut();
                  // AuthWrapper will automatically navigate to LoginScreen
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              } else if (value == 'test_notification') {
                // First check if permissions are granted
                final hasPermission =
                    await NotificationService.areNotificationsEnabled();

                if (!hasPermission) {
                  // Request permission with user-friendly dialog
                  final granted =
                      await NotificationService.requestNotificationPermissions(
                        context,
                      );

                  if (mounted) {
                    if (granted) {
                      // Permission granted, now send test notification
                      final success =
                          await NotificationService.showTestNotification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Test notification sent!'
                                : 'Failed to send notification',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    } else {
                      // Permission denied
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notification permission is required to send notifications',
                          ),
                          backgroundColor: Colors.orange,
                          action: SnackBarAction(
                            label: 'Settings',
                            onPressed: () async {
                              await NotificationService.requestNotificationPermissions(
                                context,
                              );
                            },
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  // Permission already granted, send notification
                  final success =
                      await NotificationService.showTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Test notification sent!'
                              : 'Failed to send notification',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              } else if (value == 'notification_settings') {
                // Show notification settings dialog
                if (mounted) {
                  showDialog(
                    context: context,
                    builder:
                        (BuildContext context) => NotificationSettingsDialog(),
                  );
                }
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  // PopupMenuItem<String>(
                  //   value: 'test_notification',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.notifications, color: Colors.blue),
                  //       SizedBox(width: 8),
                  //       Text('Test Notification'),
                  //     ],
                  //   ),
                  // ),
                  PopupMenuItem<String>(
                    value: 'notification_settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Notification Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Chat loading error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation by tapping the 🖉 button',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Sort chats by lastMessageTime in UI
          final sortedChats = List<QueryDocumentSnapshot>.from(chats);
          sortedChats.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['lastMessageTime'] as Timestamp?;
            final bTime = bData['lastMessageTime'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // Descending order
          });

          return ListView.builder(
            itemCount: sortedChats.length,
            itemBuilder: (context, index) {
              final chatDoc = sortedChats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              return _buildChatTile(chatData, chatDoc.id);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ComposeMessageScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.edit, color: Colors.white),
        tooltip: 'New Message',
      ),
    );
  }
}
