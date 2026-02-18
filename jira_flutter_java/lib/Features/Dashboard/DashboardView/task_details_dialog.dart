import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardViewModel/task_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectView/member_select_dialog.dart';
import 'package:jira_flutter_java/Features/User/UserModel/user_model.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class TaskDetailDialog extends StatefulWidget {
  final TaskModel task;
  final ProjectModel project;
  final TaskViewModel taskVm;

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.project,
    required this.taskVm,
  });

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  String? _selectedAssigneeUid;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _selectedAssigneeUid =
        widget.project.members.contains(widget.task.assignedUserUid)
        ? widget.task.assignedUserUid
        : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _getAssigneeName(BuildContext context, String? uid) {
    if (uid == null) return 'Not assigned';
    final userVm = context.read<UserViewModel>();
    final authVm = context.read<AuthViewModel>();
    final user = userVm.allUsers.firstWhereOrNull((u) => u.uid == uid);
    if (user == null) return 'Unknown';
    if (uid == authVm.uid) return 'You';
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

  Future<void> _pickAssignee(
    BuildContext context,
    List<UserModel> projectMembers,
  ) async {
    final initialSelected = _selectedAssigneeUid != null
        ? {_selectedAssigneeUid!}
        : <String>{};

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => MemberSelectDialog(
        initialSelected: initialSelected,
        singleSelect: true,
        hideCurrentUser: false,
        overrideUsers: projectMembers,
      ),
    );

    if (result == null) return;
    setState(() {
      _selectedAssigneeUid = result.isEmpty ? null : result.first;
    });
  }

  Future<void> _save(BuildContext context) async {
    final newTitle = _titleCtrl.text.trim();
    final newDesc = _descCtrl.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.taskVm.updateTask(
        taskId: widget.task.id,
        title: newTitle != widget.task.title ? newTitle : null,
        description: newDesc != widget.task.description ? newDesc : null,
        assignedUserUid: _selectedAssigneeUid != widget.task.assignedUserUid
            ? _selectedAssigneeUid
            : null,
        unassign: false,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _titleCtrl.text = widget.task.title;
      _descCtrl.text = widget.task.description;
      _selectedAssigneeUid = widget.task.assignedUserUid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();
    final userVm = context.watch<UserViewModel>();

    final statusColor = _getStatusColor(context, widget.task.status);
    final isCreator = authVm.uid == widget.project.creatorUid;

    final projectMembers = userVm.allUsers
        .where((u) => widget.project.members.contains(u.uid))
        .toList();

    final assigneeDisplayName = _getAssigneeName(context, _selectedAssigneeUid);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'TICKET-${widget.task.id}',
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
              widget.task.status.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          if (isCreator) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: _isEditing ? 'Cancel editing' : 'Edit task',
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit_outlined,
                size: 20,
              ),
              onPressed: _isEditing
                  ? _cancelEdit
                  : () => setState(() => _isEditing = true),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, 'Title'),
              const SizedBox(height: 6),
              _isEditing
                  ? _inputField(
                      controller: _titleCtrl,
                      context: context,
                      hint: 'Task title',
                    )
                  : _readonlyBox(context, widget.task.title),

              const SizedBox(height: 16),

              _label(context, 'Description'),
              const SizedBox(height: 6),
              _isEditing
                  ? _inputField(
                      controller: _descCtrl,
                      context: context,
                      hint: 'Task description',
                      maxLines: 4,
                      minHeight: 80,
                    )
                  : _readonlyBox(
                      context,
                      widget.task.description.isNotEmpty
                          ? widget.task.description
                          : '—',
                      minHeight: widget.task.description.isNotEmpty ? 80 : null,
                    ),

              const SizedBox(height: 16),

              _label(context, 'Assigned To'),
              const SizedBox(height: 6),
              _isEditing
                  ? InkWell(
                      onTap: () => _pickAssignee(context, projectMembers),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorScheme.primary),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                assigneeDisplayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    )
                  : _readonlyBox(
                      context,
                      widget.project.members.contains(
                            widget.task.assignedUserUid,
                          )
                          ? _getAssigneeName(
                              context,
                              widget.task.assignedUserUid,
                            )
                          : 'Not assigned',
                      icon: Icons.person,
                    ),

              const SizedBox(height: 16),

              _label(context, 'Project ID'),
              const SizedBox(height: 6),
              _readonlyBox(context, widget.task.projectId.toString()),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: _isEditing
          ? [
              TextButton(
                onPressed: _isSaving ? null : _cancelEdit,
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _save(context),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ]
          : [
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

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _readonlyBox(
    BuildContext context,
    String text, {
    IconData? icon,
    double? minHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: icon != null
          ? Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required BuildContext context,
    required String hint,
    int maxLines = 1,
    double? minHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight)
          : null,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
