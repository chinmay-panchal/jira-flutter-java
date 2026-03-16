class TaskHistoryModel {
  final int id;
  final String changedByName; // Full name, resolved on backend
  final String changedByUid;
  final String
  fieldName; // "TITLE" | "DESCRIPTION" | "STATUS" | "ASSIGNEE" | "STORY_POINTS"
  final String? oldValue;
  final String? newValue;
  final DateTime changedAt;

  const TaskHistoryModel({
    required this.id,
    required this.changedByName,
    required this.changedByUid,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.changedAt,
  });

  factory TaskHistoryModel.fromJson(Map<String, dynamic> json) {
    return TaskHistoryModel(
      id: (json['id'] as num).toInt(),
      changedByName: json['changedByName'] as String? ?? 'Unknown',
      changedByUid: json['changedByUid'] as String? ?? '',
      fieldName: json['fieldName'] as String,
      oldValue: json['oldValue'] as String?,
      newValue: json['newValue'] as String?,
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }

  /// Human-readable field label shown in the UI
  String get fieldLabel {
    switch (fieldName) {
      case 'TITLE':
        return 'Title';
      case 'DESCRIPTION':
        return 'Description';
      case 'STATUS':
        return 'Status';
      case 'ASSIGNEE':
        return 'Assignee';
      case 'STORY_POINTS':
        return 'Story Points';
      default:
        return fieldName.replaceAll('_', ' ').toLowerCase();
    }
  }

  /// Returns true when this entry is a status change — used for special chip rendering
  bool get isStatusChange => fieldName == 'STATUS';

  /// Returns true when this entry is an assignee change
  bool get isAssigneeChange => fieldName == 'ASSIGNEE';

  /// Story-point values come in as raw doubles ("3.0").  This formats them nicely.
  static String? formatPoints(String? raw) {
    if (raw == null) return null;
    final d = double.tryParse(raw);
    if (d == null) return raw;
    return d == d.truncateToDouble()
        ? d.toInt().toString()
        : d.toStringAsFixed(1);
  }
}
