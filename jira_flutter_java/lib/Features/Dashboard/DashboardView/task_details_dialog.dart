import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class TaskDetailDialog extends StatelessWidget {
  final TaskModel task;

  const TaskDetailDialog({super.key, required this.task});

  String _getAssigneeName(BuildContext context) {
    if (task.assignedUserUid == null) return 'Unassigned';

    final userVm = context.watch<UserViewModel>();
    final user = userVm.users.firstWhereOrNull(
      (u) => u.uid == task.assignedUserUid,
    );

    if (user == null) return 'Unknown';
    return '${user.firstName} ${user.lastName}'.trim();
  }

  Color _getStatusColor(BuildContext context, String status) {
    final primary = Theme.of(context).colorScheme.primary;

    switch (status) {
      case 'TODO':
        return primary;
      case 'IN_PROGRESS':
        return primary.withOpacity(0.7);
      case 'QA':
        return primary.withOpacity(0.5);
      case 'DONE':
        return primary.withOpacity(0.3);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context, task.status);
    final assigneeName = _getAssigneeName(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'TICKET-${task.id}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: Text(
              task.status.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(
              'Title',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (task.description.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Text(
                  task.description,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Assignee Section
            Text(
              'Assigned To',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    assigneeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Project ID Section
            Text(
              'Project ID',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Text(
                task.projectId.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
