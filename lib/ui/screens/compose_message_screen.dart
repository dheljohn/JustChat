import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger_app/services/chat_service.dart';
import 'package:messenger_app/ui/screens/chat_screen.dart';

class ComposeMessageScreen extends StatefulWidget {
  @override
  _ComposeMessageScreenState createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchUsers(_searchController.text);
    } else {
      setState(() {
        _searchResults.clear();
        _selectedUser = null;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Search by name (case insensitive)
      final nameQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: query + 'z')
              .limit(10)
              .get();

      // Search by email
      final emailQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
              .where('email', isLessThan: query.toLowerCase() + 'z')
              .limit(10)
              .get();

      Set<Map<String, dynamic>> results = {};

      // Add name search results
      for (var doc in nameQuery.docs) {
        results.add({
          'uid': doc.id,
          'name': doc.data()['name'] ?? '',
          'email': doc.data()['email'] ?? '',
          'avatarUrl': doc.data()['avatarUrl'] ?? '',
        });
      }

      // Add email search results
      for (var doc in emailQuery.docs) {
        results.add({
          'uid': doc.id,
          'name': doc.data()['name'] ?? '',
          'email': doc.data()['email'] ?? '',
          'avatarUrl': doc.data()['avatarUrl'] ?? '',
        });
      }

      setState(() {
        _searchResults = results.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Search error: $e');
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
      _searchController.text = user['name'] ?? user['email'];
      _searchResults.clear();
    });
  }

  Future<void> _sendMessage() async {
    if (_selectedUser == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a user and enter a message')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Create or get existing chat
      final chatId = await _chatService.createOrGetChat(
        _selectedUser!['uid'],
        _selectedUser!['name'] ?? _selectedUser!['email'],
      );

      // Send the message
      await _chatService.sendMessage(
        chatId,
        _messageController.text.trim(),
        _selectedUser!['uid'],
        _selectedUser!['name'] ?? _selectedUser!['email'],
      );

      // Navigate to chat screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  chatId: chatId,
                  otherUserName:
                      _selectedUser!['name'] ?? _selectedUser!['email'],
                  otherUserAvatar: _selectedUser!['avatarUrl'] ?? '',
                  otherUserId: _selectedUser!['uid'],
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('New Message', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isSending
              ? Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              )
              : TextButton(
                onPressed:
                    _selectedUser != null &&
                            _messageController.text.trim().isNotEmpty &&
                            !_isSending
                        ? _sendMessage
                        : null,
                child: Text(
                  'Send',
                  style: TextStyle(
                    color:
                        _selectedUser != null &&
                                _messageController.text.trim().isNotEmpty &&
                                !_isSending
                            ? Colors.blue
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'To: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      suffixIcon:
                          _isSearching
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search results
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[700],
                      backgroundImage:
                          user['avatarUrl']?.isNotEmpty == true
                              ? NetworkImage(user['avatarUrl'])
                              : null,
                      child:
                          user['avatarUrl']?.isEmpty != false
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user['email'] ?? '',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    onTap: () => _selectUser(user),
                  );
                },
              ),
            ),

          // Message input (only show if user is selected)
          if (_selectedUser != null)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  top: BorderSide(color: Colors.grey[700]!, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    onChanged:
                        (value) =>
                            setState(() {}), // Trigger rebuild for send button
                  ),
                ],
              ),
            ),

          // Empty state when no user selected and no search results
          if (_selectedUser == null &&
              _searchResults.isEmpty &&
              _searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey[600]),
                    SizedBox(height: 16),
                    Text(
                      'Search for people to message',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter a name or email to get started',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
