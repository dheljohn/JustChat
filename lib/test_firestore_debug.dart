import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDebugScreen extends StatefulWidget {
  @override
  _FirestoreDebugScreenState createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _debugInfo = 'Running tests...\n';
    });

    try {
      // Test 1: Check current user
      final user = _auth.currentUser;
      _addDebugInfo('Current user: ${user?.uid ?? 'Not logged in'}');
      _addDebugInfo('User email: ${user?.email ?? 'No email'}');
      _addDebugInfo('User name: ${user?.displayName ?? 'No name'}');

      if (user == null) {
        _addDebugInfo('ERROR: User not authenticated');
        return;
      }

      // Test 2: Try to read from users collection
      _addDebugInfo('\nTesting users collection...');
      try {
        final usersQuery = await _firestore.collection('users').limit(1).get();
        _addDebugInfo('Users collection accessible: ${usersQuery.docs.length} docs found');
      } catch (e) {
        _addDebugInfo('ERROR reading users collection: $e');
      }

      // Test 3: Try to read from chats collection
      _addDebugInfo('\nTesting chats collection...');
      try {
        final chatsQuery = await _firestore.collection('chats').limit(1).get();
        _addDebugInfo('Chats collection accessible: ${chatsQuery.docs.length} docs found');
      } catch (e) {
        _addDebugInfo('ERROR reading chats collection: $e');
      }

      // Test 4: Try to query user's chats
      _addDebugInfo('\nTesting user chats query...');
      try {
        final userChatsQuery = await _firestore
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .get();
        _addDebugInfo('User chats found: ${userChatsQuery.docs.length}');
        
        for (var doc in userChatsQuery.docs) {
          final data = doc.data();
          _addDebugInfo('Chat ${doc.id}: ${data}');
        }
      } catch (e) {
        _addDebugInfo('ERROR querying user chats: $e');
      }

      // Test 5: Try to create a test document
      _addDebugInfo('\nTesting write permissions...');
      try {
        await _firestore.collection('test').doc('debug').set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });
        _addDebugInfo('Write test successful');
        
        // Clean up
        await _firestore.collection('test').doc('debug').delete();
        _addDebugInfo('Cleanup successful');
      } catch (e) {
        _addDebugInfo('ERROR with write test: $e');
      }

    } catch (e) {
      _addDebugInfo('GENERAL ERROR: $e');
    }
  }

  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '$info\n';
    });
    print(info); // Also print to console
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Firestore Debug', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _runTests,
              child: Text('Run Tests Again'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}