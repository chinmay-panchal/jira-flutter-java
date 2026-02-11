import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:jira_flutter_java/Features/Project/ProjectModel/project_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';

class ProjectDetailsDialog extends StatelessWidget {
  final int projectId;

  const ProjectDetailsDialog({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final projectVm = context.watch<ProjectViewModel>();
    final userVm = context.watch<UserViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    final ProjectModel? project = projectVm.byId(projectId);

    if (project == null) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final bool isCreator = authVm.uid == project.creatorUid;

    final List<String> orderedMembers = [
      project.creatorUid,
      ...project.members.where((uid) => uid != project.creatorUid),
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      title: const Text('Project Details'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Name Section
              Text(
                'Project Name',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
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
                  project.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (project.description.isNotEmpty) ...[
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
                    project.description.isEmpty ? 'N/A' : project.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: project.description.isEmpty
                          ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                          : colorScheme.onSurface,
                      fontStyle: project.description.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              // Deadline Section
              Text(
                'Deadline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(project.deadline),
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
                  project.id.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Members Section Header
              Row(
                children: [
                  Icon(Icons.group, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Members (${orderedMembers.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Members List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: orderedMembers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final uid = orderedMembers[i];
                    final user = userVm.byUid(uid);

                    final bool memberIsCreator = uid == project.creatorUid;
                    final bool isYou = uid == authVm.uid;

                    final displayName = user != null
                        ? '${user.firstName} ${user.lastName}'.trim()
                        : uid;
                    final emailText = user?.email ?? '';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: memberIsCreator
                            ? colorScheme.primary.withOpacity(0.08)
                            : colorScheme.surfaceContainerHighest.withOpacity(
                                0.3,
                              ),
                        border: Border.all(
                          color: memberIsCreator
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: memberIsCreator ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: memberIsCreator
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.6),
                            child: Icon(
                              memberIsCreator ? Icons.star : Icons.person,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isYou) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (emailText.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    emailText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (memberIsCreator) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Project Creator',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (isCreator && !memberIsCreator)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: colorScheme.error,
                              tooltip: 'Remove member',
                              iconSize: 20,
                              onPressed: () async {
                                await projectVm.removeMember(
                                  projectId: project.id,
                                  memberUid: uid,
                                );

                                await projectVm.loadProjects();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
