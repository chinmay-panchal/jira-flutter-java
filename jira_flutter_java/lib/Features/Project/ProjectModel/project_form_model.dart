class ProjectFormModel {
  final String name;
  final String description;
  final List<String> members;
  final DateTime lastDate;

  ProjectFormModel({
    required this.name,
    required this.description,
    required this.members,
    required this.lastDate,
  });
}
