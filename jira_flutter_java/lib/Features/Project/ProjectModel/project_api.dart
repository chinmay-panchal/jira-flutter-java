import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../Core/network/api_constants.dart';
import '../../../Core/storage/token_storage.dart';
import 'project_request.dart';
import 'project_response.dart';

class ProjectApi {
  Future<List<ProjectResponse>> getMyProjects() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.projects),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ProjectResponse.fromJson(e)).toList();
    }
    throw Exception('Failed');
  }

  Future<void> createProject(CreateProjectRequest request) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.projects),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed');
    }
  }
}
