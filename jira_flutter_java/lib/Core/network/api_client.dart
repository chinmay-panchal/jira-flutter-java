import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        HttpHeaders.contentTypeHeader: 'application/json',
      };

  Map<String, String> get _authHeaders => {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $_token',
      };

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return http.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: auth ? _authHeaders : _headers,
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> get(
    String path, {
    bool auth = false,
  }) {
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: auth ? _authHeaders : _headers,
    );
  }
}
