import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/dataSource/data_source.dart';
import 'package:jira_flutter_java/Core/network/api_constants.dart';
import 'package:jira_flutter_java/Core/network/global_app.dart';
import 'package:jira_flutter_java/Core/storage/token_storage.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/login_request.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/login_response.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/signup_request.dart';
import 'package:jira_flutter_java/Features/Auth/AuthView/login_screen.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_request.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_response.dart';
import 'package:jira_flutter_java/Features/User/UserModel/user_model.dart';

class AppDataSource extends DataSource {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> get header => {'Content-Type': 'application/json'};

  Future<Map<String, String>> get authHeader async => {
    'Content-Type': 'application/json',
    HttpHeaders.authorizationHeader: 'Bearer ${await TokenStorage.getToken()}',
  };

  Future<void> _handle401(http.Response response) async {
    if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      GlobalApp.showSnackBar('Session expired. Please login again.');
      GlobalApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      throw Exception('Unauthorized');
    }
  }

  void _handleError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);

      // 🔥 PROJECT ACCESS REVOKED
      if (response.statusCode == 403 &&
          body is Map &&
          body['code'] == 'PROJECT_ACCESS_REVOKED') {
        throw Exception('PROJECT_ACCESS_REVOKED');
      }

      throw Exception(body['message'] ?? 'Request failed');
    }
  }

  /* -------- AUTH -------- */

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiConstants.authLogin),
      headers: header,
      body: jsonEncode(request.toJson()),
    );
    await _handle401(response);
    _handleError(response);
    return LoginResponse.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> signup(SignupRequest request) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiConstants.authSignup),
      headers: header,
      body: jsonEncode(request.toJson()),
    );
    await _handle401(response);
    _handleError(response);
  }

  @override
  Future<void> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiConstants.authSendOtp),
      headers: header,
      body: jsonEncode({'email': email}),
    );
    await _handle401(response);
    _handleError(response);
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiConstants.authVerifyOtp),
      headers: header,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    await _handle401(response);
    _handleError(response);
  }

  /* -------- PROJECT -------- */

  @override
  Future<List<ProjectResponse>> getMyProjects() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiConstants.projects),
      headers: await authHeader,
    );
    await _handle401(response);
    _handleError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => ProjectResponse.fromJson(e)).toList();
  }

  @override
  Future<void> createProject(CreateProjectRequest request) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiConstants.projects),
      headers: await authHeader,
      body: jsonEncode(request.toJson()),
    );
    await _handle401(response);
    _handleError(response);
  }

  // ✅ REMOVE MEMBER (creator only)
  @override
  Future<void> removeProjectMember({
    required int projectId,
    required String memberUid,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$projectId/members/$memberUid'),
      headers: await authHeader,
    );
    await _handle401(response);
    _handleError(response);
  }

  /* -------- TASK -------- */

  @override
  Future<List<TaskModel>> getTasksByProject(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/project/$projectId'),
      headers: await authHeader,
    );
    await _handle401(response);
    _handleError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => TaskModel.fromJson(e)).toList();
  }

  @override
  Future<void> createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: await authHeader,
      body: jsonEncode({
        'title': title,
        'description': description,
        'projectId': projectId,
        'assignedUserUid': assignedUserUid,
      }),
    );
    await _handle401(response);
    _handleError(response);
  }

  @override
  Future<void> updateTaskStatus(int taskId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/status'),
      headers: await authHeader,
      body: jsonEncode({'status': status}),
    );
    await _handle401(response);
    _handleError(response);
  }

  /* -------- USER -------- */

  @override
  Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiConstants.users),
      headers: await authHeader,
    );
    await _handle401(response);
    _handleError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  @override
  Future<List<UserModel>> getProjectMembers(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/members'),
      headers: await authHeader,
    );
    await _handle401(response);
    _handleError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }
}
