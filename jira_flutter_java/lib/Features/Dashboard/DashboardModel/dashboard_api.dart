import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../Core/network/api_constants.dart';
import '../../../Core/storage/token_storage.dart';
import 'task_model.dart';

class TaskApi {
  Future<List<TaskModel>> getTasksByProject(int projectId) async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + '/tasks/project/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => TaskModel.fromJson(e)).toList();
    }
    throw Exception('Failed');
  }

  Future<void> createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  }) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + '/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'projectId': projectId,
        'assignedUserUid': assignedUserUid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed');
    }
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    final token = await TokenStorage.getToken();
    final response = await http.patch(
      Uri.parse(ApiConstants.baseUrl + '/tasks/$taskId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed');
    }
  }
}
