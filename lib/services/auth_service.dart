import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Stream to listen for auth changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  AuthService() {
    _initializeUser();
  }

  // Initialize user when service is created
  Future<void> _initializeUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Try to load extended profile from Firestore
        UserModel? profile;
        try {
          profile = await _firestoreService.getUserProfile(user.uid);
        } catch (e) {
          debugPrint('Error loading profile on init: $e');
          // Continue even if Firestore fails
        }

        if (profile != null) {
          _currentUser = profile;
        } else {
          // Create fallback user profile
          _currentUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
          );
          // Try to create profile doc for future use
          try {
            await _firestoreService.createUserProfile(_currentUser!);
          } catch (e) {
            debugPrint('Error creating profile on init: $e');
          }
        }
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing user: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      // Build profile and save to Firestore
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? email,
        displayName: displayName,
        photoUrl: userCredential.user?.photoURL,
        bio: '',
        createdAt: DateTime.now(),
      );

      // Try to create profile in Firestore, but don't block if it fails
      try {
        await _firestoreService.createUserProfile(newUser);
      } catch (e) {
        debugPrint('Error creating profile in Firestore during signup: $e');
      }
      _currentUser = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load profile from Firestore if exists
      UserModel? profile;
      try {
        profile = await _firestoreService.getUserProfile(userCredential.user!.uid);
      } catch (e) {
        debugPrint('Error loading profile from Firestore: $e');
        // Continue even if Firestore fails, we'll use fallback
      }

      if (profile != null) {
        _currentUser = profile;
      } else {
        // If no profile doc exists or Firestore failed, create fallback profile
        final fallback = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          displayName: userCredential.user!.displayName ?? 'User',
          photoUrl: userCredential.user!.photoURL,
          bio: '',
          createdAt: userCredential.user!.metadata.creationTime ?? DateTime.now(),
        );
        _currentUser = fallback;
        
        // Try to create profile doc, but don't block if it fails
        try {
          await _firestoreService.createUserProfile(fallback);
        } catch (e) {
          debugPrint('Error creating profile in Firestore: $e');
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();

        // Update Firestore profile as well
        final updated = _currentUser?.copyWith(
          displayName: displayName ?? _currentUser?.displayName,
          photoUrl: photoUrl ?? _currentUser?.photoUrl,
        );
        if (updated != null) {
          await _firestoreService.updateUserProfile(updated.uid, updated.toJson());
          _currentUser = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  // Refresh current user data
  Future<void> refreshCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final profile = await _firestoreService.getUserProfile(user.uid);
        if (profile != null) {
          _currentUser = profile;
        } else {
          _currentUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
      rethrow;
    }
  }

  // Delete account (Firebase Auth + Firestore profile)
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final uid = user.uid;
        // delete firestore profile
        try {
          await _firestoreService.deleteUserProfile(uid);
        } catch (_) {}
        // delete firebase auth user
        await user.delete();
        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      // Rethrow so UI can handle specific FirebaseAuthException (e.g. requires-recent-login)
      rethrow;
    }
  }

  // Reauthenticate current user with password (needed for sensitive ops like delete)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in');
      final email = user.email;
      if (email == null) throw Exception('User email not available');
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      await user.reload();
      // Refresh local profile from Firestore if available
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (profile != null) {
        _currentUser = profile;
      } else {
        _currentUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
        );
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauth error: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Reauth error: $e');
      rethrow;
    }
  }
}
