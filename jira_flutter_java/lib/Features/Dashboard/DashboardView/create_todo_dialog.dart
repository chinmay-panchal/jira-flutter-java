import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Features/Project/ProjectView/member_select_dialog.dart';
import 'package:provider/provider.dart';
import '../../User/UserViewModel/user_view_model.dart';
import '../DashboardViewModel/task_view_model.dart';

class CreateTodoDialog extends StatefulWidget {
  final int projectId;
  final TaskViewModel taskVm;

  const CreateTodoDialog({
    super.key,
    required this.projectId,
    required this.taskVm,
  });

  @override
  State<CreateTodoDialog> createState() => _CreateTodoDialogState();
}

class _CreateTodoDialogState extends State<CreateTodoDialog> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  static const int descLimit = 100;
  final Set<String> selectedUids = {};

  void _showAccessRevokedDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (alertContext) => WillPopScope(
        onWillPop: () async {
          int popCount = 0;
          Navigator.of(alertContext).popUntil((route) {
            popCount++;
            return popCount >= 3 || route.isFirst;
          });
          return false;
        },
        child: AlertDialog(
          title: const Text('Access removed'),
          content: const Text('You are no longer a member of this project.'),
          actions: [
            TextButton(
              onPressed: () {
                int popCount = 0;
                Navigator.of(alertContext).popUntil((route) {
                  popCount++;
                  return popCount >= 3 || route.isFirst;
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      title: const Text('Create Todo'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
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
                final currentContext = context;
                try {
                  await currentContext.read<UserViewModel>().loadProjectMembers(
                    widget.projectId,
                  );
                } catch (_) {
                  if (!mounted) return;
                  Navigator.pop(currentContext);
                  _showAccessRevokedDialog(currentContext);
                  return;
                }

                if (!mounted) return;

                final result = await showDialog<Set<String>>(
                  context: currentContext,
                  builder: (_) => MemberSelectDialog(
                    initialSelected: selectedUids,
                    singleSelect: true,
                  ),
                );

                if (result != null && mounted) {
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
                            ? 'Assign member'
                            : '1 member selected',
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
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
          onPressed: titleCtrl.text.trim().isEmpty || selectedUids.isEmpty
              ? null
              : () async {
                  final currentContext = context;
                  try {
                    await widget.taskVm.createTask(
                      projectId: widget.projectId,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      assignedUserUid: selectedUids.first,
                    );

                    if (mounted) Navigator.pop(currentContext);
                  } catch (_) {
                    if (!mounted) return;
                    Navigator.pop(currentContext);
                    _showAccessRevokedDialog(currentContext);
                  }
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
