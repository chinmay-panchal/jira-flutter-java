import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Project/ProjectView/memer_select_dialog.dart';
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

  OutlineInputBorder _border() =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14));

  Color get _dialogBorderColor =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black;

  void _showAccessRevokedDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (alertContext) => WillPopScope(
        onWillPop: () async {
          // Handle back button press - pop 3 times to go back to project list
          int popCount = 0;
          Navigator.of(alertContext).popUntil((route) {
            popCount++;
            // Pop 3 routes: alert dialog, create todo dialog, dashboard screen
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
                // Use popUntil to safely pop multiple routes
                // This will pop: alert dialog, create todo dialog, and dashboard screen
                int popCount = 0;
                Navigator.of(alertContext).popUntil((route) {
                  popCount++;
                  // Pop 3 routes: alert dialog, create todo dialog, dashboard screen
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _dialogBorderColor, width: 1),
      ),
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

            /// Assign member
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
                  final currentContext = context;
                  try {
                    await widget.taskVm.createTask(
                      projectId: widget.projectId,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      assignedUserUid: selectedUids.isNotEmpty
                          ? selectedUids.first
                          : null,
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
