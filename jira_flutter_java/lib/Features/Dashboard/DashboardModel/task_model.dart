class TaskModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final int projectId;
  final String? assignedUserUid;
  final String createdByUid;
  final double? storyPoints; // null = unestimated, supports decimals like 1.5

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.projectId,
    this.assignedUserUid,
    required this.createdByUid,
    this.storyPoints,
  });

  // 1 story point = 1.5 hours
  static const double hoursPerPoint = 1.5;

  String get hoursLabel {
    if (storyPoints == null) return '';
    final hours = storyPoints! * hoursPerPoint;
    String hoursStr;
    if (hours == hours.truncateToDouble()) {
      hoursStr = hours.toInt().toString();
    } else {
      hoursStr = hours
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return '≈ ${hoursStr}h';
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    int? projectId,
    String? assignedUserUid,
    String? createdByUid,
    Object? storyPoints = _sentinel,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      assignedUserUid: assignedUserUid ?? this.assignedUserUid,
      createdByUid: createdByUid ?? this.createdByUid,
      storyPoints: storyPoints == _sentinel
          ? this.storyPoints
          : storyPoints as double?,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] is String
          ? json['status'] as String
          : (json['status'] as Map)['name'] as String,
      projectId: (json['projectId'] as num).toInt(),
      assignedUserUid: json['assignedUserUid'] as String?,
      createdByUid: json['createdByUid'] as String,
      storyPoints: (json['storyPoints'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'projectId': projectId,
      'assignedUserUid': assignedUserUid,
      'createdByUid': createdByUid,
      if (storyPoints != null) 'storyPoints': storyPoints,
    };
  }
}

// Sentinel so copyWith can distinguish "not passed" from "explicitly null"
const Object _sentinel = Object();
