import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jira_flutter_java/core/network/api_client.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _api = ApiClient();

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    final uid = user.uid;

    final snap = await _firestore.collection('users').doc(uid).get();
    final data = snap.data()!;

    final response = await _api.post(
      'auth/login',
      body: {
        'uid': data['uid'],
        'email': data['email'],
        'firstName': data['firstName'],
        'lastName': data['lastName'],
        'mobile': data['mobile'],
      },
    );

    final map = jsonDecode(response.body);
    final token = map['token'] as String;
    _api.setToken(token);
    return token;
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _api.setToken('');
  }
}
