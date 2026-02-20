import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Core/socket/project_socket_service.dart';
import '../ProjectModel/project_model.dart';
import '../ProjectModel/project_form_model.dart';

class ProjectViewModel extends ChangeNotifier {
  final AppRepository repo;
  final ProjectSocketService _socketService = ProjectSocketService();

  ProjectViewModel(this.repo);

  bool _disposed = false;
  bool isLoading = false;
  List<ProjectModel> projects = [];

  // Track recently processed events to prevent duplicate handling
  final Set<String> _processedEvents = {};
  static const int _eventCacheDuration = 5000; // 5 seconds

  // ← add this helper
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  ProjectModel? byId(int id) {
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── INIT ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await loadProjects();
    if (!_socketService.isConnected) {
      // ← only connect if not already connected
      await _connectSocket();
    }
  }

  Future<void> _connectSocket() async {
    _socketService.addListener(_handleSocketEvent);
    await _socketService.connect();
  }

  // ─── SOCKET EVENT HANDLER ────────────────────────────────────────────────────

  void _handleSocketEvent(ProjectSocketEvent event) {
    // Create unique event key for deduplication
    final eventKey =
        '${event.type.toString()}_${event.payload['id'] ?? event.payload['projectId']}_${event.payload['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}';

    // Skip if we've already processed this event recently
    if (_processedEvents.contains(eventKey)) {
      return;
    }

    // Add to processed events
    _processedEvents.add(eventKey);

    // Clean up old events after delay
    Future.delayed(const Duration(milliseconds: _eventCacheDuration), () {
      _processedEvents.remove(eventKey);
    });

    switch (event.type) {
      case ProjectEventType.projectCreated:
        _onProjectCreated(event.payload);
        break;

      case ProjectEventType.projectUpdated:
        _onProjectUpdated(event.payload);
        break;

      case ProjectEventType.memberAdded:
        _onMemberAdded(event.payload);
        break;

      case ProjectEventType.memberRemoved:
        _onMemberRemoved(event.payload);
        break;

      default:
        // Task events handled by TaskViewModel on dashboard screen
        break;
    }
  }

  void _onProjectCreated(Map<String, dynamic> payload) {
    // payload is full ProjectResponse
    final project = _projectFromPayload(payload);
    if (project == null) return;

    // Avoid duplicates (creator already sees it, others get it via socket)
    final exists = projects.any((p) => p.id == project.id);
    if (exists) return; // Early return, no notification needed

    // Binary search to find insertion index to maintain sorted order
    int insertIndex = _findInsertIndex(project.id);
    projects.insert(insertIndex, project);
    _safeNotify();
  }

  void _onProjectUpdated(Map<String, dynamic> payload) {
    // payload is a delta: { projectId, name?, description?, deadline? }
    final projectId = payload['projectId'] as int?;
    if (projectId == null) return;

    final index = projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    final existing = projects[index];

    projects[index] = ProjectModel(
      id: existing.id,
      name: payload['name'] as String? ?? existing.name,
      description: payload['description'] as String? ?? existing.description,
      deadline: payload['deadline'] != null
          ? DateTime.parse(payload['deadline'] as String)
          : existing.deadline,
      members: existing.members,
      creatorUid: existing.creatorUid,
    );

    _safeNotify();
  }

  void _onMemberAdded(Map<String, dynamic> payload) {
    final projectId = payload['projectId'] as int?;
    final memberUid = payload['memberUid'] as String?;
    if (projectId == null || memberUid == null) return;

    final index = projects.indexWhere((p) => p.id == projectId);

    if (index == -1) {
      // This user was just added to a project they didn't have before
      // payload contains full project for this case
      final projectData = payload['project'] as Map<String, dynamic>?;
      if (projectData != null) {
        final project = _projectFromPayload(projectData);
        if (project != null) {
          // Binary search to find insertion index to maintain sorted order
          int insertIndex = _findInsertIndex(project.id);
          projects.insert(insertIndex, project);
          _safeNotify();
        }
      }
    } else {
      // Project already in list — just update the members list
      final existing = projects[index];
      if (!existing.members.contains(memberUid)) {
        projects[index] = ProjectModel(
          id: existing.id,
          name: existing.name,
          description: existing.description,
          deadline: existing.deadline,
          members: [...existing.members, memberUid],
          creatorUid: existing.creatorUid,
        );
        _safeNotify();
      }
    }
  }

  void _onMemberRemoved(Map<String, dynamic> payload) {
    final projectId = (payload['projectId'] as num?)?.toInt();
    final memberUid = payload['memberUid'] as String?;
    if (projectId == null || memberUid == null) return;

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (memberUid == currentUserUid) {
      projects.removeWhere((p) => p.id == projectId);
      _safeNotify();
      return;
    }

    final index = projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    final existing = projects[index];
    projects[index] = ProjectModel(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      deadline: existing.deadline,
      members: existing.members.where((uid) => uid != memberUid).toList(),
      creatorUid: existing.creatorUid,
    );
    _safeNotify();
  }

  Future<void> loadProjects() async {
    isLoading = true;
    _safeNotify();

    final response = await repo.getMyProjects();
    projects = response
        .map(
          (e) => ProjectModel(
            id: e.id!.toInt(),
            name: e.name,
            description: e.description ?? '',
            deadline: e.deadline!,
            members: e.memberUids ?? [],
            creatorUid: e.creatorUid!,
          ),
        )
        .toList();

    // Sort by ID (ascending): lowest ID (earliest) first, highest ID (latest) last
    projects.sort((a, b) => a.id.compareTo(b.id));

    isLoading = false;
    _safeNotify();
  }

  // ─── SOCKET SENDS (write operations) ─────────────────────────────────────────

  void createProject(ProjectFormModel form) {
    _socketService.sendCreate({
      'name': form.name,
      'description': form.description,
      'memberUids': form.members,
      'deadline': form.lastDate.toIso8601String(),
    });
    // No await, no loadProjects() — socket event will update the list
  }

  void updateProject({
    required int projectId,
    String? name,
    String? description,
    DateTime? deadline,
  }) {
    final payload = <String, dynamic>{'projectId': projectId};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (deadline != null) payload['deadline'] = deadline.toIso8601String();
    _socketService.sendUpdate(payload);
  }

  void addMember({required int projectId, required String memberUid}) {
    _socketService.sendAddMember({
      'projectId': projectId,
      'memberUid': memberUid,
    });
  }

  void removeMember({required int projectId, required String memberUid}) {
    //  Rule: **JSON key name must match DTO field name exactly.**

    _socketService.sendRemoveMember({
      'projectId': projectId,
      'memberUid': memberUid,
    });
  }

  // ─── HELPER ──────────────────────────────────────────────────────────────────

  // Binary search to find the correct insertion index to maintain sorted order
  int _findInsertIndex(int newId) {
    int left = 0;
    int right = projects.length;

    while (left < right) {
      int mid = (left + right) ~/ 2;
      if (projects[mid].id < newId) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }

    return left;
  }

  ProjectModel? _projectFromPayload(Map<String, dynamic> map) {
    try {
      return ProjectModel(
        id: (map['id'] as num).toInt(),
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        deadline: DateTime.parse(map['deadline'] as String),
        members: List<String>.from(map['memberUids'] as List? ?? []),
        creatorUid: map['creatorUid'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _socketService.removeListener(_handleSocketEvent);
    super.dispose();
  }
}
