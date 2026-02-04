import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_constants.dart';
import 'login_request.dart';
import 'login_response.dart';
import 'signup_request.dart';

class AuthApi {
  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.authLogin),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  Future<void> signup(SignupRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.authSignup),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Signup failed');
    }
  }

  Future<void> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.authSendOtp),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Send OTP failed');
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.authVerifyOtp),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.authResetPassword),
      headers: _headers,
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Reset password failed');
    }
  }
}
