import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/dashboard_api.dart';
import '../DashboardModel/task_model.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskApi _api = TaskApi();

  bool isLoading = false;
  List<TaskModel> tasks = [];
  int? _currentProjectId;

  Future<void> loadTasks(int projectId) async {
    _currentProjectId = projectId;
    isLoading = true;
    notifyListeners();

    tasks = await _api.getTasksByProject(projectId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  }) async {
    await _api.createTask(
      projectId: projectId,
      title: title,
      description: description,
      assignedUserUid: assignedUserUid,
    );

    await loadTasks(projectId);
  }

  Future<void> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    if (_currentProjectId == null) return;

    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      tasks[taskIndex] = tasks[taskIndex].copyWith(status: status);
      notifyListeners();
    }

    await _api.updateTaskStatus(taskId, status);
  }

  List<TaskModel> byStatus(String status) {
    return tasks.where((t) => t.status == status).toList();
  }
}
