import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jira_flutter_java/Features/Project/ProjectView/member_select_dialog.dart';
import 'package:provider/provider.dart';
import '../../User/UserViewModel/user_view_model.dart';
import '../DashboardViewModel/task_view_model.dart';
import '../DashboardModel/task_model.dart';

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
  final storyPointsCtrl = TextEditingController();

  static const int descLimit = 100;

  final Set<String> selectedUids = {};

  /// Parses the story points field. Returns null if empty or invalid.
  double? get _parsedPoints {
    final text = storyPointsCtrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Live hours preview shown below the story points field.
  String get _hoursPreview {
    final pts = _parsedPoints;
    if (pts == null || pts <= 0) return '';
    final hours = pts * TaskModel.hoursPerPoint;
    String hoursStr;
    if (hours == hours.truncateToDouble()) {
      hoursStr = hours.toInt().toString();
    } else {
      hoursStr = hours
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return '= ${hoursStr}h';
  }

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
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    storyPointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _hoursPreview;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      title: const Text('Create Todo'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──────────────────────────────────────────────────────
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // ── Description ────────────────────────────────────────────────
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
              const SizedBox(height: 16),

              // ── Story Points ───────────────────────────────────────────────
              _label(context, 'Story Points'),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Number input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: TextField(
                        controller: storyPointsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          // Allow digits and a single decimal point
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. 1.5',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),

                  // Live hours preview badge
                  if (preview.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        preview,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '1 pt = ${TaskModel.hoursPerPoint}h',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),

              // ── Assignee ───────────────────────────────────────────────────
              InkWell(
                onTap: () async {
                  final currentContext = context;
                  try {
                    await currentContext
                        .read<UserViewModel>()
                        .loadProjectMembers(widget.projectId);
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
                    widget.taskVm.createTask(
                      projectId: widget.projectId,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      assignedUserUid: selectedUids.first,
                      storyPoints: _parsedPoints, // null if left blank
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
}
