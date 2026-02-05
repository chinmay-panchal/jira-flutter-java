class TaskModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final int projectId;
  final String? assignedUserUid;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.projectId,
    this.assignedUserUid,
  });

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    int? projectId,
    String? assignedUserUid,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      assignedUserUid: assignedUserUid ?? this.assignedUserUid,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      projectId: json['projectId'],
      assignedUserUid: json['assignedUserUid'],
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
    };
  }
}
