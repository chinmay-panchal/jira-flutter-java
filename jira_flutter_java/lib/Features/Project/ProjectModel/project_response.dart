class ProjectResponse {
  final int id;
  final String name;
  final DateTime deadline;

  ProjectResponse({
    required this.id,
    required this.name,
    required this.deadline,
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    return ProjectResponse(
      id: json['id'],
      name: json['name'],
      deadline: DateTime.parse(json['deadline']),
    );
  }
}
