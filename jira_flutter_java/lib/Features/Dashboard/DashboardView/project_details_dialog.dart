import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: Theme.of(context).textTheme.titleLarge),

            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  project.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.group, size: 18),
                const SizedBox(width: 8),
                Text('Members', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: orderedMembers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final uid = orderedMembers[i];
                  final user = userVm.byUid(uid);

                  final bool memberIsCreator = uid == project.creatorUid;
                  final bool isYou = uid == authVm.uid;

                  final displayName = isYou ? 'You' : (user?.email ?? uid);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: memberIsCreator
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: memberIsCreator
                              ? colorScheme.primary
                              : colorScheme.outline,
                          child: Icon(
                            memberIsCreator ? Icons.star : Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName),
                              if (memberIsCreator)
                                Text(
                                  'Project Creator',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                            ],
                          ),
                        ),

                        if (isCreator && !memberIsCreator)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: colorScheme.error,
                            tooltip: 'Remove member',
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
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
