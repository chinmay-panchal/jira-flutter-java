import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AuthModel/auth_api.dart';
import '../AuthModel/login_request.dart';
import '../AuthModel/signup_request.dart';
import '../../../Core/storage/token_storage.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? jwtToken;
  String? errorMessage;
  String? otpSessionEmail;
  String? _verificationId;
  String? userMobileNumber;
  String? userEmail;

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> updatePasswordDirectly(String newPassword) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (userEmail == null) {
        throw Exception('Email not found');
      }

      print('🔐 Resetting password for email: $userEmail');

      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await FirebaseAuth.instance.signOut();

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: userEmail!,
            password: 'temp-incorrect-password',
          );

      print('✅ Password updated successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail!);
          errorMessage = null;
          print('✅ Password reset email sent to $userEmail');
        } catch (resetError) {
          errorMessage = 'Failed to send reset email';
        }
      } else {
        errorMessage = e.message ?? 'Failed to update password';
      }
    } catch (e) {
      print('❌ Error: $e');
      errorMessage = 'An error occurred';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobile,
  }) async {
    User? firebaseUser;
    try {
      isLoading = true;
      errorMessage = null;
      jwtToken = null;
      notifyListeners();

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = cred.user;
      final uid = firebaseUser!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'mobile': mobile,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _authApi.signup(
        SignupRequest(
          uid: uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
        ),
      );

      print('✅ Signup successful');
    } catch (e) {
      errorMessage = e.toString();
      jwtToken = null;

      if (firebaseUser != null) {
        print('⚠️ Backend signup failed, rolling back Firebase user...');
        try {
          await _firestore.collection('users').doc(firebaseUser.uid).delete();
          await firebaseUser.delete();
          await FirebaseAuth.instance.signOut();
          print('✅ Firebase user deleted successfully');
        } catch (deleteError) {
          print('❌ Failed to delete Firebase user: $deleteError');
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    User? firebaseUser;
    try {
      isLoading = true;
      errorMessage = null;
      jwtToken = null;
      notifyListeners();

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = cred.user;
      final uid = firebaseUser!.uid;

      final response = await _authApi.login(
        LoginRequest(
          uid: uid,
          email: email,
          firstName: '',
          lastName: '',
          mobile: '',
        ),
      );

      jwtToken = response.token;
      await TokenStorage.saveToken(jwtToken!);
      print('✅ Login successful. JWT: $jwtToken');
    } catch (e) {
      errorMessage = e.toString();
      jwtToken = null;

      if (firebaseUser != null) {
        print('⚠️ Backend login failed, signing out from Firebase...');
        try {
          await FirebaseAuth.instance.signOut();
          print('✅ Firebase user signed out successfully');
        } catch (signOutError) {
          print('❌ Failed to sign out Firebase user: $signOutError');
        }
      }

      print('❌ Login failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      // Clear old state when starting fresh email OTP flow
      userEmail = email;
      userMobileNumber = null;
      notifyListeners();

      print('📧 Sending OTP to: $email');
      await _authApi.sendOtp(email);
      otpSessionEmail = email;
      print('✅ OTP sent successfully');
    } catch (e) {
      print('❌ Send OTP failed: $e');
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otp) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      print('🔍 Verifying OTP: $otp for email: $otpSessionEmail');

      await _authApi.verifyOtp(email: otpSessionEmail!, otp: otp);

      print('✅ OTP verified successfully');
      return true;
    } catch (e) {
      print('❌ OTP verification failed: $e');
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (otpSessionEmail == null || otpSessionEmail!.isEmpty) {
        throw Exception('Email not found. Please try again.');
      }

      print('📧 Sending password reset email to: $otpSessionEmail');

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: otpSessionEmail!,
      );

      print('✅ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      print('   Message: ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email';
      }
    } catch (e) {
      print('❌ General Error: $e');
      errorMessage = 'An error occurred. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkUserAndGetMobile(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      // Clear previous email/mobile when starting fresh mobile OTP flow
      userEmail = null;
      userMobileNumber = null;
      notifyListeners();

      print('🔍 Checking if user exists: $email');

      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        errorMessage = 'No account found with this email';
        return false;
      }

      print('✅ User exists in Firestore');

      final userData = userDoc.docs.first.data();
      userMobileNumber = userData['mobile'];
      userEmail = email; // Set fresh email

      if (userMobileNumber == null || userMobileNumber!.isEmpty) {
        errorMessage = 'No mobile number found for this account';
        return false;
      }

      if (!userMobileNumber!.startsWith('+')) {
        userMobileNumber = '+91$userMobileNumber';
      }

      print('✅ Mobile number found: $userMobileNumber');
      return true;
    } catch (e) {
      print('❌ Error: $e');
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPhoneOtpForReset({
    required BuildContext context,
    required VoidCallback onCodeSent,
    VoidCallback? onError,
  }) async {
    if (userMobileNumber == null) {
      errorMessage = 'Mobile number not found';
      notifyListeners();
      onError?.call();
      return;
    }

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      print('📱 Sending OTP to: $userMobileNumber');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: userMobileNumber!,
        timeout: const Duration(seconds: 120),

        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Auto-verification completed');
        },

        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code}');
          isLoading = false;

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Try again later';
              break;
            case 'internal-error':
              errorMessage = 'Internal error. Please try again';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }
          notifyListeners();
          onError?.call();
        },

        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP sent successfully');
          _verificationId = verificationId;
          isLoading = false;
          notifyListeners();
          onCodeSent();
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          print('⏱️ Auto-retrieval timeout');
        },
      );
    } catch (e) {
      print('❌ Send phone OTP error: $e');
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      onError?.call();
    }
  }

  Future<bool> verifyPhoneOtp(String smsCode) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (_verificationId == null) {
        throw Exception('Verification ID not found. Please try again.');
      }

      print('🔍 Verifying phone OTP: $smsCode');

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      print('✅ Phone OTP verified successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Phone OTP verification failed: ${e.code}');

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP expired. Please request a new one.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed';
      }
      return false;
    } catch (e) {
      print('❌ General error: $e');
      errorMessage = 'An error occurred. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePasswordAfterPhoneVerification(String newPassword) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (userEmail == null) {
        throw Exception('User email not found');
      }

      print('🔐 Sending password reset email to: $userEmail');

      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail!);

      print('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset failed: ${e.code}');

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'User not found';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email';
      }
    } catch (e) {
      print('❌ Error: $e');
      errorMessage = 'An error occurred';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadToken() async {
    jwtToken = await TokenStorage.getToken();
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await TokenStorage.clearToken();
    jwtToken = null;
    notifyListeners();
  }
}
