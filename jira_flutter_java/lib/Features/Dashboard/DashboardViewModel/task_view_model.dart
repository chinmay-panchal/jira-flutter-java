import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Core/socket/project_socket_service.dart';
import '../DashboardModel/task_model.dart';

class TaskViewModel extends ChangeNotifier {
  final AppRepository repo;
  final ProjectSocketService _socketService = ProjectSocketService();

  TaskViewModel(this.repo);

  bool _disposed = false;
  bool isLoading = false;
  List<TaskModel> tasks = [];
  int? _currentProjectId;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ─── INIT ────────────────────────────────────────────────────────────────────

  Future<void> loadTasks(int projectId) async {
    _currentProjectId = projectId;
    isLoading = true;
    _safeNotify();

    tasks = await repo.getTasksByProject(projectId);

    isLoading = false;
    _safeNotify();

    _socketService.removeListener(_handleSocketEvent); // remove first
    _socketService.addListener(_handleSocketEvent); // then add once
  }

  // ─── SOCKET EVENT HANDLER ────────────────────────────────────────────────────

  void _handleSocketEvent(ProjectSocketEvent event) {
    switch (event.type) {
      case ProjectEventType.taskCreated:
        _onTaskCreated(event.payload);
        break;
      case ProjectEventType.taskUpdated:
        _onTaskUpdated(event.payload);
        break;
      case ProjectEventType.taskStatusUpdated:
        _onTaskStatusUpdated(event.payload);
        break;
      case ProjectEventType.taskDeleted:
        _onTaskDeleted(event.payload);
        break;
      default:
        break;
    }
  }

  void _onTaskCreated(Map<String, dynamic> payload) {
    final task = _taskFromPayload(payload);
    if (task == null) return;
    if (task.projectId != _currentProjectId) return;

    final exists = tasks.any((t) => t.id == task.id);
    if (!exists) {
      tasks.insert(0, task);
      _safeNotify();
    }
  }

  void _onTaskUpdated(Map<String, dynamic> payload) {
    final task = _taskFromPayload(payload);
    if (task == null) return;
    if (task.projectId != _currentProjectId) return;

    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      _safeNotify();
    }
  }

  void _onTaskStatusUpdated(Map<String, dynamic> payload) {
    final taskId = (payload['taskId'] as num?)?.toInt();
    final status = payload['status'] as String?;
    final projectId = (payload['projectId'] as num?)?.toInt();

    if (taskId == null || status == null) return;
    if (projectId != _currentProjectId) return;

    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(status: status);
      _safeNotify();
    }
  }

  void _onTaskDeleted(Map<String, dynamic> payload) {
    final taskId = (payload['taskId'] as num?)?.toInt();
    if (taskId == null) return;

    tasks.removeWhere((t) => t.id == taskId);
    _safeNotify();
  }

  // ─── SOCKET SENDS ────────────────────────────────────────────────────────────

  void createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  }) {
    _socketService.sendCreateTask({
      'projectId': projectId,
      'title': title,
      'description': description,
      'assignedUserUid': assignedUserUid,
    });
  }

  void updateTaskStatus({required int taskId, required String status}) {
    if (_currentProjectId == null) return;

    // Optimistic update
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(status: status);
      _safeNotify();
    }

    _socketService.sendUpdateTaskStatus({'taskId': taskId, 'status': status});
  }

  void updateTask({
    required int taskId,
    String? title,
    String? description,
    String? assignedUserUid,
    bool unassign = false,
  }) {
    _socketService.sendUpdateTask({
      'taskId': taskId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (unassign)
        'unassign': true
      else if (assignedUserUid != null)
        'assignedUserUid': assignedUserUid,
    });
  }

  // ─── HELPER ──────────────────────────────────────────────────────────────────

  TaskModel? _taskFromPayload(Map<String, dynamic> map) {
    try {
      return TaskModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  List<TaskModel> byStatus(String status) =>
      tasks.where((t) => t.status == status).toList();

  @override
  void dispose() {
    _disposed = true;
    _socketService.removeListener(_handleSocketEvent);
    super.dispose();
  }
}
