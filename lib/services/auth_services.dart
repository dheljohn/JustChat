import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Initialize GoogleSignIn instance with minimal scopes for Spark plan
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // Only set clientId for web platform
    clientId: kIsWeb ? '327180263492-ugf77uuu3019u8gvkqk6okh34uojdjie.apps.googleusercontent.com' : null,
  );

  // -----------------------------
  // Google Sign-In
  // -----------------------------
  Future<User?> signUpWithGoogle() async {
    try {
      // For web, use Firebase Auth popup directly to avoid google_sign_in package issues
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        
        // Use signInWithPopup for web
        final result = await _auth.signInWithPopup(googleProvider);
        final firebaseUser = result.user;

        if (firebaseUser != null) {
          try {
            await _createUserProfile(
              firebaseUser,
              firebaseUser.displayName ?? "Google User",
            );
          } catch (profileError) {
            print("Profile creation error (non-critical): $profileError");
          }
        }

        return firebaseUser;
      } else {
        // For mobile, use the google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          print("Google Sign-In was cancelled by user");
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _auth.signInWithCredential(credential);
        final firebaseUser = result.user;

        if (firebaseUser != null) {
          try {
            await _createUserProfile(
              firebaseUser,
              firebaseUser.displayName ?? googleUser.displayName ?? "Google User",
            );
          } catch (profileError) {
            print("Profile creation error (non-critical): $profileError");
          }
        }

        return firebaseUser;
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        print("Firebase Auth Error: ${e.code} - ${e.message}");
        // Re-throw with more context for debugging
        throw Exception("Firebase Auth failed: ${e.code} - ${e.message}");
      } else if (e is FirebaseException) {
        print("Firebase Error: ${e.code} - ${e.message}");
        throw Exception("Firebase error: ${e.code} - ${e.message}");
      } else {
        print("Google Sign-In Error: $e");
        throw Exception("Google Sign-In failed: $e");
      }
    }
  }

  // -----------------------------
  // Google Sign-Out
  // -----------------------------
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Handle different types of exceptions safely for web compatibility
      if (e is FirebaseAuthException) {
        print("Firebase Auth Sign-Out Error: ${e.code} - ${e.message}");
      } else if (e is FirebaseException) {
        print("Firebase Sign-Out Error: ${e.code} - ${e.message}");
      } else {
        print("Sign-Out Error: $e");
      }
    }
  }

  // -----------------------------
  // Check if user is signed in with Google
  // -----------------------------
  Future<bool> isSignedInWithGoogle() async {
    return await _googleSignIn.isSignedIn();
  }

  // -----------------------------
  // Get current Google user
  // -----------------------------
  GoogleSignInAccount? getCurrentGoogleUser() {
    return _googleSignIn.currentUser;
  }

  // -----------------------------
  // Email + Password Sign-Up
  // -----------------------------
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _createUserProfile(result.user!, name);
      }

      return result.user;
    } catch (e) {
      // Handle different types of exceptions safely for web compatibility
      if (e is FirebaseAuthException) {
        print("Firebase Auth Error: ${e.code} - ${e.message}");
      } else if (e is FirebaseException) {
        print("Firebase Error: ${e.code} - ${e.message}");
      } else {
        print("Email Sign-Up Error: $e");
      }
      return null;
    }
  }

  // -----------------------------
  // Email + Password Sign-In (Login)
  // -----------------------------
  Future<User?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      print("Attempting email sign-in for: $email");
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Sign-in successful! User: ${result.user?.email}");
      return result.user;
    } catch (e) {
      // Handle different types of exceptions safely for web compatibility
      if (e is FirebaseAuthException) {
        print("Firebase Auth Error: ${e.code} - ${e.message}");
        // Re-throw the exception so the UI can handle it properly
        throw Exception("Sign-in failed: ${e.message}");
      } else if (e is FirebaseException) {
        print("Firebase Error: ${e.code} - ${e.message}");
        throw Exception("Firebase error: ${e.message}");
      } else {
        print("Email Sign-In Error: $e");
        throw Exception("Sign-in failed: $e");
      }
    }
  }

  // -----------------------------
  // Create Firestore Profile
  // -----------------------------
  Future<void> _createUserProfile(User user, String name) async {
    try {
      final doc = _db.collection('users').doc(user.uid);

      if ((await doc.get()).exists) return;

      await doc.set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),

      });
    } catch (e) {
      // Handle different types of exceptions safely for web compatibility
      if (e is FirebaseException) {
        print("Firestore Error: ${e.code} - ${e.message}");
      } else {
        print("Error creating user profile: $e");
      }
    }
  }


}
