import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';
import '../../domain/models/app_user.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  final FirebaseFirestore _firestore;
  ConfirmationResult? _webConfirmationResult;

  AuthRepository(this._auth, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromFirestore(doc);
  }

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    bool isHost = false,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final appUser = AppUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        photoUrl: '',
        isHost: isHost,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(appUser.toMap());
    }
  }

  Future<void> upgradeToHost(String uid) async {
    await _firestore.collection('users').doc(uid).update({'isHost': true});
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific Google Sign-In
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
        await _signInWithProvider(googleProvider);
      } else {
        // Mobile Google Sign-In
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await _signInWithCredential(credential);
        }
      }
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }





  Future<void> _signInWithProvider(AuthProvider provider) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithPopup(provider);
      await _createUserInFirestore(userCredential.user);
    } catch (e) {
      // Fallback to redirect if popup fails (common on mobile web)
      // For now just rethrow, but in prod consider signInWithRedirect
      rethrow;
    }
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    await _createUserInFirestore(userCredential.user);
  }

  Future<void> _createUserInFirestore(User? user) async {
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL ?? '',
          isHost: false,
        );
        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      }
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    if (kIsWeb) {
      try {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
        // On web, we don't get a verification ID in the same way, 
        // but we need to trigger the callback to move to the next step.
        // We pass a dummy verification ID.
        onCodeSent('web_verification_id', null);
      } catch (e) {
        onVerificationFailed(
          FirebaseAuthException(
            code: 'web-auth-failed',
            message: e.toString(),
          ),
        );
      }
    } else {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
          onVerificationCompleted(credential);
        },
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
    }
  }

  Future<void> signInWithPhoneCredential(String verificationId, String smsCode) async {
    try {
      if (kIsWeb) {
        if (_webConfirmationResult != null) {
          final userCredential = await _webConfirmationResult!.confirm(smsCode);
          await _createUserInFirestore(userCredential.user);
        } else {
          throw Exception('Web confirmation result is missing');
        }
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        await _signInWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Failed to sign in with phone: $e');
    }
  }

  Future<bool> checkUserExists(String email) async {
    try {
      // First try to fetch sign in methods (fastest if allowed)
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) return true;
      } catch (_) {
        // Ignore error and fall back to Firestore
      }

      // Fallback: Check Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check user existence: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
Future<AppUser?> currentUser(CurrentUserRef ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getCurrentUser();
}
