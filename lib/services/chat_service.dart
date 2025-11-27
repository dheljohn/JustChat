import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique chat ID for two users
  String generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ensure consistent ordering
    return ids.join('_');
  }

  // Create or get existing chat
  Future<String> createOrGetChat(String otherUserId, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final chatId = generateChatId(currentUser.uid, otherUserId);

    // Check if chat already exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Create new chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, otherUserId],
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? 'Unknown',
          otherUserId: otherUserName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': '',
      });
    }

    return chatId;
  }

  // Update user's last seen timestamp
  Future<void> updateLastSeen() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      });
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String message, String otherUserId, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Add message to messages subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': message,
      'senderId': currentUser.uid,
      'senderName': currentUser.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // Update chat document with last message info
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': currentUser.uid,
      'participantNames': {
        currentUser.uid: currentUser.displayName ?? 'Unknown',
        otherUserId: otherUserName,
      },
    });

    // Local notifications will be handled automatically by NotificationService listener
  }



  // Get user's chats
  Stream<QuerySnapshot> getUserChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Remove orderBy to avoid composite index requirement
    // We'll sort in the UI instead
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots();
  }

  // Get chat messages
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}