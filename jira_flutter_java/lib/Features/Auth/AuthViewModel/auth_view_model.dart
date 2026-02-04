import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AuthModel/auth_api.dart';
import '../AuthModel/login_request.dart';
import '../AuthModel/signup_request.dart';
import '../../../Core/storage/token_storage.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();

  bool isLoading = false;
  String? jwtToken;
  String? errorMessage;
  String? otpSessionEmail;

  void clearError() {
    errorMessage = null;
    notifyListeners();
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
