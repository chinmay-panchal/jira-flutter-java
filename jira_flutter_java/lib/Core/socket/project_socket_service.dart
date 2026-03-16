import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:jira_flutter_java/Core/storage/token_storage.dart';

enum ProjectEventType {
  projectCreated,
  projectUpdated,
  memberAdded,
  memberRemoved,
  taskCreated,
  taskUpdated,
  taskStatusUpdated,
  taskDeleted,
  unknown,
}

class ProjectSocketEvent {
  final ProjectEventType type;
  final Map<String, dynamic> payload;
  final int timestamp;

  ProjectSocketEvent({
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  factory ProjectSocketEvent.fromJson(Map<String, dynamic> json) {
    return ProjectSocketEvent(
      type: _parseType(json['type'] as String? ?? ''),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  static ProjectEventType _parseType(String raw) {
    switch (raw) {
      case 'PROJECT_CREATED':
        return ProjectEventType.projectCreated;
      case 'PROJECT_UPDATED':
        return ProjectEventType.projectUpdated;
      case 'MEMBER_ADDED':
        return ProjectEventType.memberAdded;
      case 'MEMBER_REMOVED':
        return ProjectEventType.memberRemoved;
      case 'TASK_CREATED':
        return ProjectEventType.taskCreated;
      case 'TASK_UPDATED':
        return ProjectEventType.taskUpdated;
      case 'TASK_STATUS_UPDATED':
        return ProjectEventType.taskStatusUpdated;
      case 'TASK_DELETED':
        return ProjectEventType.taskDeleted;
      default:
        return ProjectEventType.unknown;
    }
  }
}

class ProjectSocketService {
  static final ProjectSocketService _instance =
      ProjectSocketService._internal();
  factory ProjectSocketService() => _instance;
  ProjectSocketService._internal();

  static const String _baseUrl = 'ws://localhost:8080/ws/websocket';
  StompClient? _client;
  bool _isConnected = false;

  Future<void> connect() async {
    if (_isConnected || _client != null) return;
    final token = await TokenStorage.getToken();
    if (token == null) return;

    _client = StompClient(
      config: StompConfig(
        url: _baseUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onDisconnect: (_) {
          _isConnected = false;
          print('STOMP disconnected');
        },
        onStompError: (frame) {
          _isConnected = false;
          print('STOMP error: ${frame.body}');
        },
        onWebSocketError: (error) {
          _isConnected = false;
          print('WebSocket error: $error');
        },
        onDebugMessage: (msg) => print('STOMP debug: $msg'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;

    _client!.subscribe(
      destination: '/user/queue/projects',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          final event = ProjectSocketEvent.fromJson(json);
          _dispatch(event);
        } catch (e) {
          // malformed frame, ignore
        }
      },
    );
  }

  void sendCreate(Map<String, dynamic> payload) =>
      _send('/app/projects.create', payload);

  void sendUpdate(Map<String, dynamic> payload) =>
      _send('/app/projects.update', payload);

  void sendAddMember(Map<String, dynamic> payload) =>
      _send('/app/projects.addMember', payload);

  void sendRemoveMember(Map<String, dynamic> payload) =>
      _send('/app/projects.removeMember', payload);

  void sendCreateTask(Map<String, dynamic> payload) =>
      _send('/app/tasks.create', payload);

  void sendUpdateTaskStatus(Map<String, dynamic> payload) =>
      _send('/app/tasks.updateStatus', payload);

  void sendUpdateTask(Map<String, dynamic> payload) =>
      _send('/app/tasks.update', payload);

  void sendMoveTask(Map<String, dynamic> payload) =>
      _send('/app/tasks.move', payload);

  void _send(String destination, Map<String, dynamic> payload) {
    if (_client == null || !_isConnected) return;
    debugPrint('WS SEND → $destination: ${jsonEncode(payload)}');
    _client!.send(
      destination: destination,
      body: jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  }

  final List<void Function(ProjectSocketEvent)> _listeners = [];

  void addListener(void Function(ProjectSocketEvent) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(ProjectSocketEvent) listener) {
    _listeners.remove(listener);
  }

  void _dispatch(ProjectSocketEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
