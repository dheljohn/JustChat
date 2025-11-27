import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // ----------------------------------------------
  // Create 1:1 Chat
  // ----------------------------------------------
  Future<String> createChat(String otherUserId) async {
    final chats =
        await _db
            .collection('chats')
            .where('members', arrayContains: uid)
            .get();

    // Find existing 1:1 chat
    for (var doc in chats.docs) {
      final members = List<String>.from(doc['members']);
      if (members.contains(otherUserId) && members.length == 2) {
        return doc.id;
      }
    }

    // Create new chat
    final doc = await _db.collection('chats').add({
      'isGroup': false,
      'members': [uid, otherUserId],
      'admins': [],
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'lastMessage': null,
    });

    return doc.id;
  }

  // ----------------------------------------------
  // Send Text Message
  // ----------------------------------------------
  Future<void> sendTextMessage(String chatId, String text) async {
    final message = {
      'senderId': uid,
      'text': text,
      'type': 'text',
      'mediaUrl': null,
      'thumbnailUrl': null,
      'timestamp': DateTime.now(),
      'deliveredTo': [],
      'readBy': [],
      'replyTo': null,
      'reactions': {},
    };

    final msgDoc = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message);

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': {
        'text': text,
        'senderId': uid,
        'timestamp': DateTime.now(),
        'type': 'text',
      },
      'updatedAt': DateTime.now(),
    });
  }

  // ----------------------------------------------
  // Send Media Message
  // ----------------------------------------------
  Future<void> sendMedia(
    String chatId,
    String mediaUrl,
    String? thumbnailUrl,
    String type,
  ) async {
    final message = {
      'senderId': uid,
      'text': null,
      'type': type,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'timestamp': DateTime.now(),
      'deliveredTo': [],
      'readBy': [],
      'replyTo': null,
      'reactions': {},
    };

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message);

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': {
        'text': type.toUpperCase(),
        'senderId': uid,
        'timestamp': DateTime.now(),
        'type': type,
      },
      'updatedAt': DateTime.now(),
    });
  }

  // ----------------------------------------------
  // Typing Indicator
  // ----------------------------------------------
  Future<void> setTyping(String chatId, bool isTyping) async {
    await _db.collection('chats').doc(chatId).collection('typing').doc(uid).set(
      {'isTyping': isTyping},
    );
  }
}
