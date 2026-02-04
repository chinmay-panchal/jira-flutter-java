class CreateProjectRequest {
  final String name;
  final String description;
  final List<String> memberUids;
  final DateTime deadline;

  CreateProjectRequest({
    required this.name,
    required this.description,
    required this.memberUids,
    required this.deadline,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'memberUids': memberUids,
        'deadline': deadline.toIso8601String(),
      };
}
