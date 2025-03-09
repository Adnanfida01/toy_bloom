import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;
  String? _profileImageUrl;
  String _displayName = 'Guest';
  bool _initialized = false;

  AuthProvider() {
    print('AuthProvider initialized');
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    try {
      // Wait for Firebase Auth to initialize
      await Future.delayed(Duration(milliseconds: 500));

      _auth.authStateChanges().listen((user) async {
        print('Auth state changed: ${user?.email}');
        _user = user;
        if (user != null) {
          await _loadUserData();
          _initialized = true;
        } else {
          _userData = null;
          _isAdmin = false;
          _profileImageUrl = null;
          _displayName = 'Guest';
          _initialized = true;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing auth: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  bool get isInitialized => _initialized;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAdmin => _isAdmin;
  String get displayName => _displayName;
  String? get profileImageUrl => _profileImageUrl;

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      print('Loading user data for: ${_user!.email}');
      final doc = await _firestore.collection('users').doc(_user!.uid).get();

      if (doc.exists) {
        _userData = doc.data();
        _displayName =
            _userData?['displayName'] ?? _userData?['name'] ?? 'Guest';
        _profileImageUrl = _userData?['profileImageUrl'];

        // Special case to set admin flag for specific emails
        if (_user!.email == 'advortexmain@gmail.com' ||
            _user!.email == 'admin@toybloom.com') {
          _isAdmin = true;
          // Update the user document if needed
          if (_userData?['isAdmin'] != true) {
            await _firestore.collection('users').doc(_user!.uid).update({
              'isAdmin': true,
            });
          }
        } else {
          _isAdmin = _userData?['isAdmin'] ?? false;
        }

        print(
            'User data loaded - isAdmin: $_isAdmin, displayName: $_displayName');
      } else {
        // Create user document if it doesn't exist
        final bool isAdminEmail = _user!.email == 'admin@toybloom.com' ||
            _user!.email == 'advortexmain@gmail.com';

        await _firestore.collection('users').doc(_user!.uid).set({
          'email': _user!.email,
          'displayName': _user!.displayName ?? 'Guest',
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': isAdminEmail, // Set admin flag for specific emails
        });

        _displayName = _user!.displayName ?? 'Guest';
        _isAdmin = isAdminEmail;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      // First check if user exists
      final userExists = await checkUserExists(email);
      if (userExists) {
        throw Exception('An account already exists with this email address');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      final bool isAdminEmail =
          email == 'admin@toybloom.com' || email == 'advortexmain@gmail.com';

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'displayName': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': isAdminEmail,
        'emailVerified': false,
      });

      _user = userCredential.user;
      _displayName = name;
      _isAdmin = isAdminEmail;

      // Instead of throwing an error, we'll return normally
      // The UI will show the verification dialog
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      final result = await verifyCode(email, code);
      if (!result) {
        throw Exception('Invalid verification code');
      }

      // Update user's email verification status
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'emailVerified': true,
        });

        // Reload user to update emailVerified status
        await _user!.reload();
        _user = _auth.currentUser;
      }
    } catch (e) {
      print('Email verification error: $e');
      rethrow;
    }
  }

  Future<bool> checkEmailVerified(String email) async {
    try {
      // Reload the current user to get fresh data
      if (_auth.currentUser != null) {
        await _auth.currentUser!.reload();
        return _auth.currentUser!.emailVerified;
      }
      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        // Send verification email if not verified
        await userCredential.user!.sendEmailVerification();
        throw Exception(
            'Please verify your email address. A new verification email has been sent.');
      }

      // If login is successful and it's the admin email
      if (email == 'advortexmain@gmail.com' || email == 'admin@toybloom.com') {
        _isAdmin = true;
        notifyListeners();
      }

      // Load user data
      await _loadUserData();
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      // First check if user exists
      final userExists = await checkUserExists(email);
      if (!userExists) {
        throw Exception('No account found with this email address');
      }

      // Try to sign in without password to get user object
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (!methods.contains('password')) {
        throw Exception(
            'This email is not registered with password authentication');
      }

      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == email) {
        await currentUser.sendEmailVerification();
      } else {
        throw Exception(
            'Please try signing in again to resend verification email');
      }
    } catch (e) {
      print('Error resending verification email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userData = null;
      _isAdmin = false;
      _profileImageUrl = null;
      _displayName = 'Guest';
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? imageUrl}) async {
    if (_user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updates = <String, dynamic>{};

      if (displayName != null && displayName.isNotEmpty) {
        updates['displayName'] = displayName;
        updates['name'] = displayName; // Update both fields for compatibility
        _displayName = displayName;
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        updates['profileImageUrl'] = imageUrl;
        _profileImageUrl = imageUrl;
      }

      if (updates.isEmpty) {
        return; // Nothing to update
      }

      // Update Firestore first
      await _firestore.collection('users').doc(_user!.uid).update(updates);

      // Then update Firebase Auth profile
      if (displayName != null && displayName.isNotEmpty) {
        await _user!.updateDisplayName(displayName);
      }

      // Reload user data to ensure everything is in sync
      await _user!.reload();
      _user = _auth.currentUser;
      await _loadUserData();

      notifyListeners();
      print('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  // Check if a user is admin
  Future<bool> checkIfAdmin() async {
    if (_user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final isAdmin = doc.data()?['isAdmin'] ?? false;
        _isAdmin = isAdmin;
        notifyListeners();
        return isAdmin;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Make a user an admin (for testing purposes)
  Future<void> makeAdmin() async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'isAdmin': true,
      });

      _isAdmin = true;
      notifyListeners();
    } catch (e) {
      print('Error making user admin: $e');
      rethrow;
    }
  }

  // Reset password with verification code
  Future<void> resetPasswordWithCode(String email, String newPassword) async {
    try {
      // First verify the user exists
      final userExists = await checkUserExists(email);
      if (!userExists) {
        throw Exception('No account found with this email address');
      }

      // Use Firebase Auth's resetPassword endpoint
      await _auth.confirmPasswordReset(
        code: await _getResetCode(email),
        newPassword: newPassword,
      );

      // Update the password in Firestore as well
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (userDoc.docs.isNotEmpty) {
        await _firestore.collection('users').doc(userDoc.docs.first.id).update({
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  Future<String> _getResetCode(String email) async {
    try {
      final doc =
          await _firestore.collection('verification_codes').doc(email).get();
      if (!doc.exists) {
        throw Exception('Verification code not found');
      }
      return doc.data()?['code'] ?? '';
    } catch (e) {
      print('Error getting reset code: $e');
      rethrow;
    }
  }

  // Sign up with verification
  Future<void> signUpWithVerification(
      String email, String password, String name) async {
    try {
      // Delete the verification code
      await _firestore.collection('verification_codes').doc(email).delete();

      // Proceed with signup
      await signUp(email, password, name);
    } catch (e) {
      print('Error in signup with verification: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Check if user exists by email
  Future<bool> checkUserExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Send verification code for signup
  Future<void> sendSignupVerificationCode(String email) async {
    try {
      // Check if user already exists
      final userExists = await checkUserExists(email);
      if (userExists) {
        throw Exception('An account already exists with this email address');
      }

      // Generate a random 4-digit code
      final code = (1000 + Random().nextInt(9000)).toString();

      // Store the code in Firestore with timestamp
      await _firestore.collection('verification_codes').doc(email).set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'signup',
      });

      // TODO: In production, implement email sending with Firebase Functions
      print('Signup verification code for $email: $code');

      // For demonstration, you can implement actual email sending here
      // This would typically be done with a Firebase Cloud Function
    } catch (e) {
      print('Error sending signup verification code: $e');
      rethrow;
    }
  }

  // Send verification code
  Future<void> sendVerificationCode(String email,
      {bool isPasswordReset = false}) async {
    try {
      // Check if user exists
      final userExists = await checkUserExists(email);
      if (!userExists) {
        throw Exception('No account found with this email address');
      }

      // Generate a random 4-digit code
      final code = (1000 + Random().nextInt(9000)).toString();

      // Store the code in Firestore with timestamp
      await _firestore.collection('verification_codes').doc(email).set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
        'type': isPasswordReset ? 'password_reset' : 'verification',
      });

      // TODO: In production, implement email sending with Firebase Functions
      print('Verification code for $email: $code');

      // For demonstration, you can implement actual email sending here
      // This would typically be done with a Firebase Cloud Function
    } catch (e) {
      print('Error sending verification code: $e');
      rethrow;
    }
  }

  // Verify code
  Future<bool> verifyCode(String email, String enteredCode) async {
    try {
      // Get the stored code from Firestore
      final doc =
          await _firestore.collection('verification_codes').doc(email).get();

      if (!doc.exists) {
        return false;
      }

      final storedCode = doc.data()?['code'];
      final timestamp = doc.data()?['timestamp'] as Timestamp?;

      // Check if code is expired (more than 10 minutes old)
      if (timestamp != null) {
        final expirationTime = timestamp.toDate().add(Duration(minutes: 10));
        if (DateTime.now().isAfter(expirationTime)) {
          // Code expired
          return false;
        }
      }

      // Compare codes
      return storedCode == enteredCode;
    } catch (e) {
      print('Error verifying code: $e');
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Create a new Google Sign-In instance
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Trigger the Google Sign-In flow
      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Google Sign-In failed');
      }

      // Check if this is a new user (sign up) or existing user (sign in)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // This is a new user, create their profile in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName ?? 'Guest',
          'name': user.displayName ?? 'Guest',
          'profileImageUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': user.email == 'advortexmain@gmail.com' ||
              user.email == 'admin@toybloom.com',
          'emailVerified': true, // Google accounts are pre-verified
        });
      }

      // Load user data
      await _loadUserData();
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Generate a random 6-digit code
  String _generateVerificationCode() {
    Random random = Random();
    return (100000 + random.nextInt(900000))
        .toString(); // Generates a number between 100000 and 999999
  }

  // Send verification code via email
  Future<String> sendEmailVerificationCode(String email) async {
    try {
      // Generate a 6-digit code
      String verificationCode = _generateVerificationCode();

      // Create a custom template for the verification email
      String emailTemplate = """
        Your verification code for ToyBloom is: $verificationCode
        
        Please enter this code in the app to verify your email address.
        
        If you didn't request this code, please ignore this email.
      """;

      // Send the email using Firebase Custom Email Action Handler
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url:
              'https://toybloom-8c1e7.firebaseapp.com/?email=$email&code=$verificationCode',
          handleCodeInApp: true,
          androidPackageName: 'com.example.toy_bloom',
          androidInstallApp: true,
          androidMinimumVersion: '1',
        ),
      );

      // Store the verification code temporarily (you might want to use a more secure storage)
      await FirebaseFirestore.instance
          .collection('verification_codes')
          .doc(email)
          .set({
        'code': verificationCode,
        'createdAt': FieldValue.serverTimestamp(),
        'isUsed': false
      });

      return verificationCode;
    } catch (e) {
      print('Error sending verification code: $e');
      throw e;
    }
  }

  // Verify the code entered by user
  Future<bool> verifyEmailCode(String email, String enteredCode) async {
    try {
      // Get the stored verification code
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('verification_codes')
          .doc(email)
          .get();

      if (!doc.exists) {
        return false;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Check if code is correct and not used
      if (data['code'] == enteredCode && data['isUsed'] == false) {
        // Mark code as used
        await doc.reference.update({'isUsed': true});

        // Mark the user's email as verified in Firebase Auth
        if (_auth.currentUser != null) {
          await _auth.currentUser!.updateEmail(email);
          await _auth.currentUser!.sendEmailVerification();
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying code: $e');
      return false;
    }
  }

  // Add this method to your AuthProvider class
  Exception _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No account found with this email address');
        case 'wrong-password':
          return Exception('Invalid password');
        case 'invalid-email':
          return Exception('Invalid email address');
        case 'user-disabled':
          return Exception('This account has been disabled');
        case 'email-already-in-use':
          return Exception('An account already exists with this email');
        case 'operation-not-allowed':
          return Exception('Operation not allowed. Please contact support.');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later.');
        default:
          return Exception(e.message ?? 'An unknown error occurred');
      }
    }
    return Exception('An unexpected error occurred');
  }
}
