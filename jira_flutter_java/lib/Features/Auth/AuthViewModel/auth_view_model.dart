import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Core/network/global_app.dart';
import 'package:jira_flutter_java/Features/Auth/AuthView/login_screen.dart';
import '../../../Core/storage/token_storage.dart';
import '../AuthModel/login_request.dart';
import '../AuthModel/signup_request.dart';

class AuthViewModel extends ChangeNotifier {
  final AppRepository repo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel(this.repo);

  bool isLoading = false;
  String? jwtToken;
  String? errorMessage;
  String? otpSessionEmail;
  String? _verificationId;
  String? userMobileNumber;
  String? userEmail;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  void clearError() {
    errorMessage = null;
    notifyListeners();
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

      firebaseUser = cred.user!;
      final uid = firebaseUser.uid;

      final response = await repo.login(
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
    } catch (e) {
      errorMessage = e.toString();
      jwtToken = null;

      if (firebaseUser != null) {
        await FirebaseAuth.instance.signOut();
      }
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
      notifyListeners();

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = cred.user!;
      final uid = firebaseUser.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'mobile': mobile,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await repo.signup(
        SignupRequest(
          uid: uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
        ),
      );
    } catch (e) {
      errorMessage = e.toString();

      if (firebaseUser != null) {
        await _firestore.collection('users').doc(firebaseUser.uid).delete();
        await firebaseUser.delete();
        await FirebaseAuth.instance.signOut();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      userEmail = email;
      notifyListeners();

      await repo.sendOtp(email);
      otpSessionEmail = email;
    } catch (e) {
      errorMessage = e.toString();
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

      await repo.verifyOtp(otpSessionEmail!, otp);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePasswordDirectly(String newPassword) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (userEmail == null) {
        throw Exception('Email not found');
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail!);
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Failed to reset password';
    } catch (_) {
      errorMessage = 'An error occurred';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword() async {
    if (otpSessionEmail == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: otpSessionEmail!);
  }

  Future<bool> checkUserAndGetMobile(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        errorMessage = 'No account found';
        return false;
      }

      final data = snap.docs.first.data();
      userMobileNumber = data['mobile'];
      userEmail = email;

      if (!userMobileNumber!.startsWith('+')) {
        userMobileNumber = '+91$userMobileNumber';
      }

      return true;
    } catch (e) {
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

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: userMobileNumber!,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          errorMessage = e.message;
          isLoading = false;
          notifyListeners();
          onError?.call();
        },
        codeSent: (id, _) {
          _verificationId = id;
          isLoading = false;
          notifyListeners();
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      onError?.call();
    }
  }

  Future<bool> verifyPhoneOtp(String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }
}
