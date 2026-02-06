class ProjectResponse {
  final int? id;
  final String name;
  final String? description;
  final DateTime? deadline;
  final String? creatorUid;
  final List<String>? memberUids;
  final DateTime? createdAt;

  ProjectResponse({
    this.id,
    required this.name,
    this.description,
    this.deadline,
    this.creatorUid,
    this.memberUids,
    this.createdAt,
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    return ProjectResponse(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      creatorUid: json['creatorUid'],
      memberUids: (json['memberUids'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
