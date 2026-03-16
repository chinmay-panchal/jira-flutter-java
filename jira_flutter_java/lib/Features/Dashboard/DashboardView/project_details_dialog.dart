import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:jira_flutter_java/Features/Project/ProjectModel/project_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectView/member_select_dialog.dart';

class ProjectDetailsDialog extends StatefulWidget {
  final int projectId;

  const ProjectDetailsDialog({super.key, required this.projectId});

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  bool _isEditing = false;
  final bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  DateTime? _selectedDeadline;

  bool _isAddingMember = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _enterEditMode(ProjectModel project) {
    _nameCtrl.text = project.name;
    _descCtrl.text = project.description;
    _selectedDeadline = project.deadline;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  Future<void> _save(BuildContext context, ProjectModel project) async {
    final projectVm = context.read<ProjectViewModel>();

    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name cannot be empty')),
      );
      return;
    }

    // Fire via socket — no await
    projectVm.updateProject(
      projectId: project.id,
      name: newName != project.name ? newName : null,
      description: _descCtrl.text.trim() != project.description
          ? _descCtrl.text.trim()
          : null,
      deadline:
          _selectedDeadline != null && _selectedDeadline != project.deadline
          ? _selectedDeadline
          : null,
    );

    // Close edit mode immediately — UI will update when socket event arrives
    setState(() => _isEditing = false);
    Navigator.pop(context);
  }

  /// Opens MemberSelectDialog showing only users NOT already in the project.
  /// Multi-select, same as CreateProjectDialog.
  Future<void> _openAddMemberPicker(
    BuildContext context,
    ProjectModel project,
  ) async {
    final userVm = context.read<UserViewModel>();
    final fetchedAllUsers = await userVm.fetchAllUsers();
    if (!context.mounted) return;

    final currentMemberUids = Set<String>.from(project.members);

    final eligibleUsers = fetchedAllUsers
        .where((u) => !currentMemberUids.contains(u.uid))
        .toList();

    Set<String>? result;

    result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => MemberSelectDialog(
        initialSelected: const {},
        hideCurrentUser: false,
        overrideUsers: eligibleUsers,
      ),
    );

    if (result == null || result.isEmpty) return;
    if (!context.mounted) return;

    final projectVm = context.read<ProjectViewModel>();
    setState(() => _isAddingMember = true);

    try {
      for (final uid in result) {
        projectVm.addMember(projectId: project.id, memberUid: uid); // no await
      }
      if (context.mounted) {
        setState(() => _isAddingMember = false);
        Navigator.pop(context); // close dialog, list updates via socket
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isAddingMember = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectVm = context.watch<ProjectViewModel>();
    final userVm = context.watch<UserViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    final ProjectModel? project = projectVm.byId(widget.projectId);

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
      title: Row(
        children: [
          const Expanded(child: Text('Project Details')),
          if (isCreator)
            IconButton(
              tooltip: _isEditing ? 'Cancel editing' : 'Edit project',
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit_outlined,
                size: 20,
              ),
              onPressed: _isEditing
                  ? _cancelEdit
                  : () => _enterEditMode(project),
            ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ──────────────────────────────────────────────────────
                _label(context, 'Project Name'),
                const SizedBox(height: 6),
                _isEditing
                    ? _inputField(
                        controller: _nameCtrl,
                        context: context,
                        hint: 'Project name',
                      )
                    : _readonlyBox(
                        context,
                        project.name,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),

                const SizedBox(height: 16),

                // ── Description ───────────────────────────────────────────────
                _label(context, 'Description'),
                const SizedBox(height: 6),
                _isEditing
                    ? _inputField(
                        controller: _descCtrl,
                        context: context,
                        hint: 'Project description (optional)',
                        maxLines: 3,
                        minHeight: 80,
                      )
                    : _readonlyBox(
                        context,
                        project.description.isNotEmpty
                            ? project.description
                            : 'N/A',
                        minHeight: 80,
                        italic: project.description.isEmpty,
                      ),

                const SizedBox(height: 16),

                // ── Deadline ──────────────────────────────────────────────────
                _label(context, 'Deadline'),
                const SizedBox(height: 6),
                _isEditing
                    ? _deadlinePicker(context, colorScheme)
                    : _readonlyBox(
                        context,
                        DateFormat('MMM dd, yyyy').format(project.deadline),
                        icon: Icons.calendar_today,
                      ),

                const SizedBox(height: 16),

                // ── Project ID ────────────────────────────────────────────────
                _label(context, 'Project ID'),
                const SizedBox(height: 6),
                _readonlyBox(context, project.id.toString()),

                const SizedBox(height: 16),

                // ── Members header ────────────────────────────────────────────
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
                    const Spacer(),
                    // Add Member button — creator only, always visible
                    if (isCreator)
                      _isAddingMember
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: () =>
                                  _openAddMemberPicker(context, project),
                              icon: const Icon(
                                Icons.person_add_outlined,
                                size: 16,
                              ),
                              label: const Text('Add'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Member list ───────────────────────────────────────────────
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                              onPressed: () {
                                context.read<ProjectViewModel>().removeMember(
                                  projectId: project.id,
                                  memberUid: uid,
                                );
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
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
                onPressed: _isSaving ? null : () => _save(context, project),
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
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    bool italic = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: italic ? colorScheme.onSurfaceVariant.withOpacity(0.6) : null,
    );
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
                Text(text, style: style),
              ],
            )
          : Text(text, style: style),
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

  Widget _deadlinePicker(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _pickDeadline(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.primary),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _selectedDeadline != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDeadline!)
                  : 'Pick a date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _selectedDeadline != null
                    ? null
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_outlined, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
