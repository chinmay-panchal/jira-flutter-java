import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Project/ProjectView/memer_select_dialog.dart';
import '../../User/UserViewModel/user_view_model.dart';
import '../DashboardViewModel/task_view_model.dart';

class CreateTodoDialog extends StatefulWidget {
  final int projectId;

  const CreateTodoDialog({super.key, required this.projectId});

  @override
  State<CreateTodoDialog> createState() => _CreateTodoDialogState();
}

class _CreateTodoDialogState extends State<CreateTodoDialog> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  static const int descLimit = 100;
  final Set<String> selectedUids = {};

  OutlineInputBorder _border() =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Create Todo'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                border: _border(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              maxLength: descLimit,
              decoration: InputDecoration(
                labelText: 'Description',
                border: _border(),
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
                await context.read<UserViewModel>().loadProjectMembers(
                  widget.projectId,
                );

                final result = await showDialog<Set<String>>(
                  context: context,
                  builder: (_) => MemberSelectDialog(
                    initialSelected: selectedUids,
                    singleSelect: true,
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
                  border: Border.all(color: Colors.grey.shade400),
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
          onPressed: titleCtrl.text.trim().isEmpty
              ? null
              : () async {
                  await context.read<TaskViewModel>().createTask(
                    projectId: widget.projectId,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    assignedUserUid: selectedUids.isNotEmpty
                        ? selectedUids.first
                        : null,
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
