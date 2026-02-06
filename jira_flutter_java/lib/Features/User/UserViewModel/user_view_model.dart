import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import '../UserModel/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final AppRepository repo;

  UserViewModel(this.repo);

  List<UserModel> _allUsers = [];
  List<UserModel> users = [];
  bool isLoading = false;

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    _allUsers = await repo.getAllUsers();
    users = _allUsers;

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadProjectMembers(int projectId) async {
    isLoading = true;
    notifyListeners();

    _allUsers = await repo.getProjectMembers(projectId);
    users = _allUsers;

    isLoading = false;
    notifyListeners();
  }

  UserModel? byUid(String uid) {
    try {
      return _allUsers.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
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
