import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import '../DashboardModel/task_model.dart';

class TaskViewModel extends ChangeNotifier {
final AppRepository repo;

TaskViewModel(this.repo);

bool isLoading = false;
List<TaskModel> tasks = [];
int? _currentProjectId;

Future<void> loadTasks(int projectId) async {
  _currentProjectId = projectId;
  isLoading = true;
  notifyListeners();

  tasks = await repo.getTasksByProject(projectId);

  isLoading = false;
  notifyListeners();
}

Future<void> createTask({
  required int projectId,
  required String title,
  required String description,
  String? assignedUserUid,
}) async {
  await repo.createTask(
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

  final index = tasks.indexWhere((t) => t.id == taskId);
  if (index != -1) {
    tasks[index] = tasks[index].copyWith(status: status);
    notifyListeners();
  }

  await repo.updateTaskStatus(taskId, status);
}

List<TaskModel> byStatus(String status) {
  return tasks.where((t) => t.status == status).toList();
}
}
