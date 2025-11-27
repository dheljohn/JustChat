import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateDebugScreen extends StatefulWidget {
  @override
  _AuthStateDebugScreenState createState() => _AuthStateDebugScreenState();
}

class _AuthStateDebugScreenState extends State<AuthStateDebugScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auth State Debug'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auth State Debug Info:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text('Connection State: ${snapshot.connectionState}'),
                SizedBox(height: 10),
                Text('Has Data: ${snapshot.hasData}'),
                SizedBox(height: 10),
                Text('Data: ${snapshot.data}'),
                SizedBox(height: 10),
                if (snapshot.hasData && snapshot.data != null) ...[
                  Text('User Email: ${snapshot.data!.email}'),
                  Text('User UID: ${snapshot.data!.uid}'),
                  Text('User Display Name: ${snapshot.data!.displayName}'),
                  SizedBox(height: 20),
                  Text(
                    '✅ USER IS AUTHENTICATED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ] else ...[
                  Text(
                    '❌ USER IS NOT AUTHENTICATED',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: Text('Sign Out'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
