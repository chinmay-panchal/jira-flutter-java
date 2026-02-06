class ProjectModel {
  final int id;
  final String name;
  final String description;
  final DateTime deadline;
  final List<String> members;
  final String creatorUid;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    required this.members,
    required this.creatorUid,
  });
}
