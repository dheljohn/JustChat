import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInDebugScreen extends StatefulWidget {
  @override
  _GoogleSignInDebugScreenState createState() => _GoogleSignInDebugScreenState();
}

class _GoogleSignInDebugScreenState extends State<GoogleSignInDebugScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  String _debugInfo = 'Ready to test Google Sign-In';
  bool _isLoading = false;

  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '\n\n' + DateTime.now().toString() + ':\n' + info;
    });
    print(info);
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Starting Google Sign-In test...';
    });

    try {
      _addDebugInfo('Step 1: Checking if Google Play Services are available...');
      
      _addDebugInfo('Step 2: Attempting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _addDebugInfo('ERROR: Google Sign-In was cancelled by user or failed');
        return;
      }

      _addDebugInfo('SUCCESS: Google Sign-In successful!');
      _addDebugInfo('User: ${googleUser.displayName}');
      _addDebugInfo('Email: ${googleUser.email}');

      _addDebugInfo('Step 3: Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      _addDebugInfo('Access Token: ${googleAuth.accessToken != null ? "Present" : "Missing"}');
      _addDebugInfo('ID Token: ${googleAuth.idToken != null ? "Present" : "Missing"}');

      _addDebugInfo('Step 4: Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _addDebugInfo('Step 5: Signing in to Firebase...');
      final result = await FirebaseAuth.instance.signInWithCredential(credential);

      if (result.user != null) {
        _addDebugInfo('SUCCESS: Firebase authentication successful!');
        _addDebugInfo('Firebase User: ${result.user!.displayName}');
        _addDebugInfo('Firebase UID: ${result.user!.uid}');
      } else {
        _addDebugInfo('ERROR: Firebase authentication failed - no user returned');
      }

    } catch (e) {
      _addDebugInfo('ERROR: Exception occurred: $e');
      _addDebugInfo('Error Type: ${e.runtimeType}');
      
      if (e is FirebaseAuthException) {
        _addDebugInfo('Firebase Auth Error Code: ${e.code}');
        _addDebugInfo('Firebase Auth Error Message: ${e.message}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      _addDebugInfo('Sign-out successful');
    } catch (e) {
      _addDebugInfo('Sign-out error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Sign-In Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGoogleSignIn,
                    child: _isLoading 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Test Google Sign-In'),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _signOut,
                  child: Text('Sign Out'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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