import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TestGoogleSignIn extends StatefulWidget {
  @override
  _TestGoogleSignInState createState() => _TestGoogleSignInState();
}

class _TestGoogleSignInState extends State<TestGoogleSignIn> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId:
        '327180263492-ugf77uuu3019u8gvkqk6okh34uojdjie.apps.googleusercontent.com',
  );

  String _status = 'Ready to test';
  GoogleSignInAccount? _currentUser;

  Future<void> _testSignIn() async {
    setState(() {
      _status = 'Starting Google Sign-In...';
    });

    try {
      if (kIsWeb) {
        print('Step 1: Using Firebase Auth popup for web');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');

        final result = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
        final user = result.user;

        print('Step 2: Firebase Auth completed, user: ${user?.email}');

        if (user != null) {
          setState(() {
            _status = 'SUCCESS: Signed in as ${user.email} via Firebase Auth';
          });
        } else {
          setState(() {
            _status = 'Sign-in failed - no user returned';
          });
        }
      } else {
        print('Step 1: Using google_sign_in package for mobile');
        final GoogleSignInAccount? user = await _googleSignIn.signIn();

        print('Step 2: Sign-in completed, user: ${user?.email}');

        if (user != null) {
          print('Step 3: Getting authentication');
          final GoogleSignInAuthentication auth = await user.authentication;
          print(
            'Step 4: Got tokens - Access: ${auth.accessToken != null}, ID: ${auth.idToken != null}',
          );

          setState(() {
            _currentUser = user;
            _status = 'SUCCESS: Signed in as ${user.email}';
          });
        } else {
          setState(() {
            _status = 'Sign-in was cancelled';
          });
        }
      }
    } catch (e) {
      print('Error during sign-in: $e');
      setState(() {
        _status = 'FAILED: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Sign-In Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_status'),
            SizedBox(height: 20),
            if (_currentUser != null) ...[
              Text('User: ${_currentUser!.email}'),
              Text('Name: ${_currentUser!.displayName}'),
              Text('Photo: ${_currentUser!.photoUrl}'),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _testSignIn,
              child: Text('Test Google Sign-In'),
            ),
          ],
        ),
      ),
    );
  }
}
