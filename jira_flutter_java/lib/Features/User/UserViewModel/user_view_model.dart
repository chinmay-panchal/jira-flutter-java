import 'package:flutter/material.dart';
import '../UserModel/user_api.dart';
import '../UserModel/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserApi _api = UserApi();

  List<UserModel> users = [];
  bool isLoading = false;

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    users = await _api.getAllUsers();

    isLoading = false;
    notifyListeners();
  }

  Future<void> search(String q) async {
    if (q.isEmpty) {
      await loadUsers();
      return;
    }

    users = await _api.searchUsers(q);
    notifyListeners();
  }
}
