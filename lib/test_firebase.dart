import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_services.dart';

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final AuthService _authService = AuthService();
  String _status = 'Ready to test Firebase';

  void _testFirebaseConnection() async {
    setState(() {
      _status = 'Testing Firebase connection...';
    });

    try {
      // Test Firestore connection
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection')
          .set({'timestamp': FieldValue.serverTimestamp()});
      
      setState(() {
        _status = 'Firebase connected successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Firebase connection failed: $e';
      });
    }
  }

  void _testGoogleSignIn() async {
    setState(() {
      _status = 'Testing Google Sign-In...';
    });

    try {
      print('Starting Google Sign-In test...');
      final user = await _authService.signUpWithGoogle();
      print('Google Sign-In result: $user');
      
      if (user != null) {
        setState(() {
          _status = 'Google Sign-In successful: ${user.email}';
        });
      } else {
        setState(() {
          _status = 'Google Sign-In cancelled or failed - check console for details';
        });
      }
    } catch (e) {
      print('Google Sign-In exception: $e');
      setState(() {
        _status = 'Google Sign-In error: $e';
      });
    }
  }

  void _testEmailSignUp() async {
    setState(() {
      _status = 'Testing Email Sign-Up...';
    });

    try {
      final user = await _authService.signUpWithEmail(
        'test@example.com',
        'password123',
        'Test User',
      );
      if (user != null) {
        setState(() {
          _status = 'Email Sign-Up successful: ${user.email}';
        });
      } else {
        setState(() {
          _status = 'Email Sign-Up failed';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Email Sign-Up error: $e';
      });
    }
  }

  void _testDirectGoogleSignIn() async {
    setState(() {
      _status = 'Testing Direct Google Sign-In...';
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      print('GoogleSignIn instance created');
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print('GoogleSignIn.signIn() result: $googleUser');
      
      if (googleUser == null) {
        setState(() {
          _status = 'Google Sign-In was cancelled';
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Got authentication: ${googleAuth.accessToken != null}');

      setState(() {
        _status = 'Direct Google Sign-In successful: ${googleUser.email}';
      });
    } catch (e) {
      print('Direct Google Sign-In error: $e');
      setState(() {
        _status = 'Direct Google Sign-In error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Firebase Connection Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Text(_status),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testFirebaseConnection,
              child: Text('Test Firebase Connection'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testGoogleSignIn,
              child: Text('Test Google Sign-In'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testEmailSignUp,
              child: Text('Test Email Sign-Up'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testDirectGoogleSignIn,
              child: Text('Test Direct Google Sign-In'),
            ),
            SizedBox(height: 20),
            Text(
              'Current User: ${FirebaseAuth.instance.currentUser?.email ?? 'Not signed in'}',
            ),
          ],
        ),
      ),
    );
  }
}