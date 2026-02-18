import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import '../UserModel/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final AppRepository repo;

  UserViewModel(this.repo);

  List<UserModel> allUsers = [];
  List<UserModel> _projectMembers = [];
  List<UserModel> users = [];
  bool isLoading = false;

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    allUsers = await repo.getAllUsers();
    users = allUsers;

    isLoading = false;
    notifyListeners();
  }

  Future<List<UserModel>> fetchAllUsers() async {
    allUsers = await repo.getAllUsers();
    return allUsers;
  }

  Future<void> loadProjectMembers(int projectId) async {
    isLoading = true;
    notifyListeners();

    _projectMembers = await repo.getProjectMembers(projectId);
    users = _projectMembers;

    for (final u in _projectMembers) {
      if (!allUsers.any((a) => a.uid == u.uid)) {
        allUsers = [...allUsers, u];
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProjectMembers(int projectId) async {
    _projectMembers = await repo.getProjectMembers(projectId);
    users = _projectMembers;

    for (final u in _projectMembers) {
      if (!allUsers.any((a) => a.uid == u.uid)) {
        allUsers = [...allUsers, u];
      }
    }

    notifyListeners();
  }

  UserModel? byUid(String uid) {
    try {
      return allUsers.firstWhere((u) => u.uid == uid);
    } catch (_) {
      try {
        return _projectMembers.firstWhere((u) => u.uid == uid);
      } catch (_) {
        return null;
      }
    }
  }

  void search(String q) {
    final query = q.toLowerCase().trim();

    if (query.isEmpty) {
      users = _projectMembers.isNotEmpty ? _projectMembers : allUsers;
      notifyListeners();
      return;
    }

    final source = _projectMembers.isNotEmpty ? _projectMembers : allUsers;
    users = source.where((u) {
      final fullName = '${u.firstName} ${u.lastName}'.toLowerCase();
      return fullName.contains(query) || u.email.toLowerCase().contains(query);
    }).toList();

    notifyListeners();
  }
}
