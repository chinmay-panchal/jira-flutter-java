import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Features/Project/ProjectView/member_select_dialog.dart';
import 'package:provider/provider.dart';

import '../../User/UserViewModel/user_view_model.dart';
import '../ProjectModel/project_form_model.dart';
import '../ProjectViewModel/project_view_model.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  static const int descLimit = 100;
  DateTime? deadline;

  final Set<String> selectedUids = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      title: const Text('Create Project'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Project name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              maxLength: descLimit,
              decoration: const InputDecoration(
                labelText: 'Description',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${descCtrl.text.length} / $descLimit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                await context.read<UserViewModel>().loadUsers();

                final result = await showDialog<Set<String>>(
                  context: context,
                  builder: (_) => MemberSelectDialog(
                    initialSelected: selectedUids,
                    hideCurrentUser: true,
                  ),
                );

                if (result != null) {
                  setState(() {
                    selectedUids
                      ..clear()
                      ..addAll(result);
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedUids.isEmpty
                            ? 'Select members'
                            : '${selectedUids.length} members selected',
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => deadline = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(14),
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
                      deadline == null
                          ? 'Select deadline'
                          : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: deadline == null
              ? null
              : () async {
                  await context.read<ProjectViewModel>().createProject(
                    ProjectFormModel(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      members: selectedUids.toList(),
                      lastDate: deadline!,
                    ),
                  );
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
