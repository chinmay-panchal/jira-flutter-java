import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jira_flutter_java/Core/network/api_constants.dart';
import '../../../Core/storage/token_storage.dart';
import 'user_model.dart';

class UserApi {
  Future<List<UserModel>> getAllUsers() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.users),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final list = jsonDecode(response.body) as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> searchUsers(String q) async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userSearch}?q=$q'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final list = jsonDecode(response.body) as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }
}
