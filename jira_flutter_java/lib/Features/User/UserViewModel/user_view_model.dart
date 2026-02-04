import 'package:flutter/material.dart';
import '../UserModel/user_api.dart';
import '../UserModel/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserApi _api = UserApi();

  List<UserModel> _allUsers = [];
  List<UserModel> users = [];
  bool isLoading = false;

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    _allUsers = await _api.getAllUsers();
    users = _allUsers;

    isLoading = false;
    notifyListeners();
  }

  void search(String q) {
    final query = q.toLowerCase().trim();

    users = _allUsers.where((u) {
      final fullName = '${u.firstName} ${u.lastName}'.toLowerCase();
      return fullName.contains(query) || u.email.toLowerCase().contains(query);
    }).toList();

    notifyListeners();
  }
}
