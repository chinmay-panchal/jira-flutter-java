import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_history_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// ─── Status colour helpers (mirrored from task_detail_dialog.dart) ────────────

const _statusLabels = <String, String>{
  'TODO': 'To Do',
  'IN_PROGRESS': 'In Progress',
  'QA': 'QA',
  'DONE': 'Done',
};

String _statusLabel(String s) => _statusLabels[s] ?? s.replaceAll('_', ' ');

Color _statusColor(String s) {
  switch (s) {
    case 'TODO':
      return const Color(0xFF6B778C);
    case 'IN_PROGRESS':
      return const Color(0xFF0052CC);
    case 'QA':
      return const Color(0xFF8777D9);
    case 'DONE':
      return const Color(0xFF36B37E);
    default:
      return const Color(0xFF6B778C);
  }
}

Color _statusBgLight(String s) {
  switch (s) {
    case 'TODO':
      return const Color(0xFFF4F5F7);
    case 'IN_PROGRESS':
      return const Color(0xFFDEEBFF);
    case 'QA':
      return const Color(0xFFEAE6FF);
    case 'DONE':
      return const Color(0xFFE3FCEF);
    default:
      return const Color(0xFFF4F5F7);
  }
}

Color _statusBgDark(String s) {
  switch (s) {
    case 'TODO':
      return const Color(0xFF2C333A);
    case 'IN_PROGRESS':
      return const Color(0xFF0C2D6B);
    case 'QA':
      return const Color(0xFF2E2057);
    case 'DONE':
      return const Color(0xFF0D3D2B);
    default:
      return const Color(0xFF2C333A);
  }
}

// ─── Field icon map ────────────────────────────────────────────────────────────

IconData _fieldIcon(String fieldName) {
  switch (fieldName) {
    case 'TITLE':
      return Icons.title_rounded;
    case 'DESCRIPTION':
      return Icons.subject_rounded;
    case 'STATUS':
      return Icons.swap_horiz_rounded;
    case 'ASSIGNEE':
      return Icons.person_rounded;
    case 'STORY_POINTS':
      return Icons.bolt_rounded;
    default:
      return Icons.edit_rounded;
  }
}

Color _fieldAccent(String fieldName, ColorScheme cs) {
  switch (fieldName) {
    case 'STATUS':
      return const Color(0xFF0052CC);
    case 'ASSIGNEE':
      return const Color(0xFF8777D9);
    case 'STORY_POINTS':
      return const Color(0xFFF59E0B);
    case 'TITLE':
      return cs.primary;
    case 'DESCRIPTION':
      return const Color(0xFF36B37E);
    default:
      return cs.primary;
  }
}

// ─── Entry point: show the bottom sheet ──────────────────────────────────────

Future<void> showTaskHistorySheet({
  required BuildContext context,
  required int taskId,
  required String taskTitle,
  required AppRepository repo,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => TaskHistoryBottomSheet(
      taskId: taskId,
      taskTitle: taskTitle,
      repo: repo,
    ),
  );
}

// ─── Bottom sheet widget ──────────────────────────────────────────────────────

class TaskHistoryBottomSheet extends StatefulWidget {
  final int taskId;
  final String taskTitle;
  final AppRepository repo;

  const TaskHistoryBottomSheet({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.repo,
  });

  @override
  State<TaskHistoryBottomSheet> createState() => _TaskHistoryBottomSheetState();
}

class _TaskHistoryBottomSheetState extends State<TaskHistoryBottomSheet> {
  late Future<List<TaskHistoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getTaskHistory(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;

    final surface = isDark ? const Color(0xFF161B27) : Colors.white;
    final handleColor = isDark ? Colors.white24 : Colors.black12;
    final labelColor = isDark
        ? const Color(0xFF8C96A8)
        : const Color(0xFF6B778C);
    final textColor = isDark
        ? const Color(0xFFDDE3EE)
        : const Color(0xFF172B4D);
    final border = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);
    final emptyColor = isDark
        ? const Color(0xFF4A5568)
        : const Color(0xFFB3BAC5);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.5, 0.65, 0.92],
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            widget.taskTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: labelColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1, color: border),

              // ── Body ─────────────────────────────────────────────────────────
              Expanded(
                child: FutureBuilder<List<TaskHistoryModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading(cs);
                    }

                    if (snapshot.hasError) {
                      return _buildError(
                        labelColor,
                        cs,
                        snapshot.error.toString(),
                      );
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return _buildEmpty(emptyColor, isDark);
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        final isLast = i == items.length - 1;
                        final myUid = ctx.read<AuthViewModel>().uid;
                        final isMe = item.changedByUid == myUid;

                        return _HistoryTile(
                          item: item,
                          isLast: isLast,
                          isMe: isMe,
                          isDark: isDark,
                          cs: cs,
                          textColor: textColor,
                          labelColor: labelColor,
                          border: border,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading history…',
            style: TextStyle(fontSize: 13, color: cs.primary.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color labelColor, ColorScheme cs, String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load history',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              err,
              style: TextStyle(
                fontSize: 12,
                color: labelColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _future = widget.repo.getTaskHistory(widget.taskId);
              }),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(Color emptyColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 52,
            color: emptyColor.withOpacity(0.4),
          ),
          const SizedBox(height: 14),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: emptyColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Changes to this task will appear here.',
            style: TextStyle(fontSize: 13, color: emptyColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

// ─── Individual history tile ──────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final TaskHistoryModel item;
  final bool isLast;
  final bool isMe;
  final bool isDark;
  final ColorScheme cs;
  final Color textColor;
  final Color labelColor;
  final Color border;

  const _HistoryTile({
    required this.item,
    required this.isLast,
    required this.isMe,
    required this.isDark,
    required this.cs,
    required this.textColor,
    required this.labelColor,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _fieldAccent(item.fieldName, cs);
    final icon = _fieldIcon(item.fieldName);
    final timeStr = _formatTime(item.changedAt);
    final dateStr = _formatDate(item.changedAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline spine ──────────────────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Icon dot
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withOpacity(isDark ? 0.35 : 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                // Vertical line to next tile
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: border,
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: who + when
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Avatar(name: item.changedByName, cs: cs, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: isMe ? 'You' : item.changedByName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              TextSpan(
                                text: '  ·  $timeStr',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Field badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.fieldLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Change body
                  _buildChangeBody(context),

                  const SizedBox(height: 6),

                  // Date
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: labelColor.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBody(BuildContext context) {
    // ── Status: show coloured chips with arrow ─────────────────────────────────
    if (item.isStatusChange) {
      return Row(
        children: [
          if (item.oldValue != null) ...[
            _StatusChip(status: item.oldValue!, isDark: isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: labelColor,
              ),
            ),
          ],
          if (item.newValue != null)
            _StatusChip(status: item.newValue!, isDark: isDark)
          else
            Text(
              'Cleared',
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      );
    }

    // ── Assignee: names with arrow ─────────────────────────────────────────────
    if (item.isAssigneeChange) {
      final accent = _fieldAccent(item.fieldName, cs);
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          if (item.oldValue != null)
            _NameChip(name: item.oldValue!, accent: labelColor, isDark: isDark),
          if (item.oldValue != null)
            Icon(Icons.arrow_forward_rounded, size: 14, color: labelColor),
          if (item.newValue != null)
            _NameChip(name: item.newValue!, accent: accent, isDark: isDark)
          else
            Text(
              'Unassigned',
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      );
    }

    // ── Story points ──────────────────────────────────────────────────────────
    if (item.fieldName == 'STORY_POINTS') {
      final oldPts = TaskHistoryModel.formatPoints(item.oldValue);
      final newPts = TaskHistoryModel.formatPoints(item.newValue);
      return Row(
        children: [
          if (oldPts != null) ...[
            _PointsChip(label: '$oldPts pt', isDark: isDark, dimmed: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: labelColor,
              ),
            ),
          ],
          if (newPts != null)
            _PointsChip(label: '$newPts pt', isDark: isDark, dimmed: false)
          else
            Text(
              'Removed',
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      );
    }

    // ── Title / Description: old → new text diff ──────────────────────────────
    final isDesc = item.fieldName == 'DESCRIPTION';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.oldValue != null)
          _DiffBlock(
            text: item.oldValue!,
            isAdded: false,
            isDark: isDark,
            maxLines: isDesc ? 3 : 1,
          ),
        if (item.oldValue != null && item.newValue != null)
          const SizedBox(height: 4),
        if (item.newValue != null)
          _DiffBlock(
            text: item.newValue!,
            isAdded: true,
            isDark: isDark,
            maxLines: isDesc ? 3 : 1,
          ),
        if (item.newValue == null)
          Text(
            'Cleared',
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  // ── Time helpers ─────────────────────────────────────────────────────────────

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  static String _formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy  HH:mm').format(dt);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final ColorScheme cs;
  final double size;

  const _Avatar({required this.name, required this.cs, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.44,
          fontWeight: FontWeight.w700,
          color: cs.onPrimary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusChip({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final bg = isDark ? _statusBgDark(status) : _statusBgLight(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  final String name;
  final Color accent;
  final bool isDark;

  const _NameChip({
    required this.name,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: accent,
        ),
      ),
    );
  }
}

class _PointsChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool dimmed;

  const _PointsChip({
    required this.label,
    required this.isDark,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: amber.withOpacity(
          dimmed ? (isDark ? 0.08 : 0.06) : (isDark ? 0.18 : 0.10),
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: amber.withOpacity(dimmed ? 0.2 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 12,
            color: amber.withOpacity(dimmed ? 0.5 : 1.0),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: amber.withOpacity(dimmed ? 0.5 : 1.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffBlock extends StatelessWidget {
  final String text;
  final bool isAdded;
  final bool isDark;
  final int maxLines;

  const _DiffBlock({
    required this.text,
    required this.isAdded,
    required this.isDark,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAdded
        ? const Color(0xFF36B37E)
        : (isDark ? const Color(0xFF8C96A8) : const Color(0xFF6B778C));
    final bg = isAdded
        ? const Color(0xFF36B37E).withOpacity(isDark ? 0.10 : 0.06)
        : (isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdded ? '+' : '−',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(isAdded ? 0.9 : 0.65),
                height: 1.5,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

//
