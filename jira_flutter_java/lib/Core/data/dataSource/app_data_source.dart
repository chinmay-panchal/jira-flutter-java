import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jira_flutter_java/Core/data/dataSource/data_source.dart';
import 'package:jira_flutter_java/Core/network/api_constants.dart';
import 'package:jira_flutter_java/Core/network/global_app.dart';
import 'package:jira_flutter_java/Core/storage/token_storage.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/login_request.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/login_response.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/signup_request.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_history_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_request.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_response.dart';
import 'package:jira_flutter_java/Features/User/UserModel/user_model.dart';

class AppDataSource extends DataSource {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> get header => {'Content-Type': 'application/json'};

  Future<Map<String, String>> get authHeader async {
    final token = await TokenStorage.getToken();
    print('TOKEN: $token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _handle401(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Check if it's a project access revoked case — let _handleError deal with that
      if (response.statusCode == 403 && response.body.isNotEmpty) {
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['code'] == 'PROJECT_ACCESS_REVOKED') return;
        } catch (_) {}
      }

      await TokenStorage.clearToken();
      GlobalApp.showSessionExpiredDialog();
      throw Exception('Unauthorized');
    }
  }

  void _handleError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.body.isEmpty) {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
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

  // ✅ EDIT PROJECT (creator only) — name, description, deadline
  @override
  Future<ProjectResponse> updateProject({
    required int projectId,
    String? name,
    String? description,
    DateTime? deadline,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (deadline != null) body['deadline'] = deadline.toIso8601String();

    final response = await http.patch(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: await authHeader,
      body: jsonEncode(body),
    );
    await _handle401(response);
    _handleError(response);
    return ProjectResponse.fromJson(jsonDecode(response.body));
  }

  // ✅ ADD MEMBER (creator only)
  @override
  Future<ProjectResponse> addProjectMember({
    required int projectId,
    required String memberUid,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/members'),
      headers: await authHeader,
      body: jsonEncode({'memberUid': memberUid}),
    );
    await _handle401(response);
    _handleError(response);
    return ProjectResponse.fromJson(jsonDecode(response.body));
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

  @override
  Future<TaskModel> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? assignedUserUid,
    bool unassign = false,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (unassign) {
      body['unassign'] = true;
    } else if (assignedUserUid != null) {
      body['assignedUserUid'] = assignedUserUid;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: await authHeader,
      body: jsonEncode(body),
    );
    await _handle401(response);
    _handleError(response);
    return TaskModel.fromJson(jsonDecode(response.body));
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

  @override
  Future<List<TaskHistoryModel>> getTaskHistory(int taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/history'),
      headers: await authHeader,
    );
    await _handle401(response);
    _handleError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => TaskHistoryModel.fromJson(e)).toList();
  }
}
