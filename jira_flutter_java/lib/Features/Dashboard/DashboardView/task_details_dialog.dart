import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/task_history_bototm_sheet.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardViewModel/task_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectView/member_select_dialog.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserModel/user_model.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

const _statusLabels = <String, String>{
  'TODO': 'To Do',
  'IN_PROGRESS': 'In Progress',
  'QA': 'QA',
  'DONE': 'Done',
};

String _statusLabel(String s) => _statusLabels[s] ?? s.replaceAll('_', ' ');

Color _statusColor(String s, ColorScheme cs) {
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
      return cs.primary;
  }
}

Color _statusBg(String s) {
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

class _TaskDetailDialogState extends State<TaskDetailDialog>
    with SingleTickerProviderStateMixin {
  bool _editingTitle = false;
  bool _editingDesc = false;
  bool _editingPoints = false;
  bool _saved = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _pointsCtrl;

  String? _selectedAssigneeUid;
  late String _currentStatus;

  late String _pendingTitle;
  late String _pendingDesc;

  late final AnimationController _ac;
  late final Animation<double> _anim;

  static const _allStatuses = ['TODO', 'IN_PROGRESS', 'QA', 'DONE'];

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _pointsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
    _pendingTitle = widget.task.title;
    _pendingDesc = widget.task.description;

    _savedTitle = widget.task.title;
    _savedDesc = widget.task.description;
    _savedPoints = _ptsStr(widget.task.storyPoints);
    _savedAssigneeUid =
        widget.project.members.contains(widget.task.assignedUserUid)
        ? widget.task.assignedUserUid
        : null;

    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _pointsCtrl = TextEditingController(text: _ptsStr(widget.task.storyPoints));
    _selectedAssigneeUid =
        widget.project.members.contains(widget.task.assignedUserUid)
        ? widget.task.assignedUserUid
        : null;

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);

    widget.taskVm.addListener(_onVmChanged);

    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus && _editingTitle) _commitTitle();
    });
    _descFocus.addListener(() {
      if (!_descFocus.hasFocus && _editingDesc) _commitDesc();
    });
    _pointsFocus.addListener(() {
      if (!_pointsFocus.hasFocus && _editingPoints) _commitPoints();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _pointsFocus.dispose();
    _ac.dispose();
    widget.taskVm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    final live = widget.taskVm.tasks.firstWhereOrNull(
      (t) => t.id == widget.task.id,
    );
    if (live == null) return;

    setState(() {
      if (!_editingTitle && _pendingTitle == _savedTitle) {
        _pendingTitle = live.title;
        _savedTitle = live.title;
        _titleCtrl.text = live.title;
      }

      if (!_editingDesc && _pendingDesc == _savedDesc) {
        _pendingDesc = live.description;
        _savedDesc = live.description;
        _descCtrl.text = live.description;
      }

      _currentStatus = live.status;

      if (_selectedAssigneeUid == _savedAssigneeUid) {
        final liveAssignee =
            widget.project.members.contains(live.assignedUserUid)
            ? live.assignedUserUid
            : null;
        _selectedAssigneeUid = liveAssignee;
        _savedAssigneeUid = liveAssignee;
      }

      if (!_editingPoints && _pointsCtrl.text.trim() == _savedPoints) {
        final livepts = _ptsStr(live.storyPoints);
        _pointsCtrl.text = livepts;
        _savedPoints = livepts;
      }
    });
  }

  static String _ptsStr(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  double? get _parsedPts {
    final s = _pointsCtrl.text.trim();
    return s.isEmpty ? null : double.tryParse(s);
  }

  String get _hoursPreview {
    final p = _parsedPts;
    if (p == null || p <= 0) return '';
    final h = p * TaskModel.hoursPerPoint;
    final s = h == h.truncateToDouble()
        ? h.toInt().toString()
        : h
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
    return '≈ ${s}h';
  }

  String _assigneeName(BuildContext ctx, String? uid) {
    if (uid == null) return 'Unassigned';
    final u = ctx.read<UserViewModel>().allUsers.firstWhereOrNull(
      (x) => x.uid == uid,
    );
    if (u == null) return 'Unknown';
    if (uid == ctx.read<AuthViewModel>().uid) return 'You';
    return '${u.firstName} ${u.lastName}'.trim();
  }

  void _commitTitle() {
    final v = _titleCtrl.text.trim();
    if (v.isEmpty) {
      _titleCtrl.text = _pendingTitle;
    } else {
      _pendingTitle = v;
    }
    setState(() => _editingTitle = false);
  }

  void _commitDesc() {
    _pendingDesc = _descCtrl.text.trim();
    setState(() => _editingDesc = false);
  }

  void _commitPoints() {
    setState(() => _editingPoints = false);
  }

  void _openStatusMenu(BuildContext chipCtx, ColorScheme cs, bool isDark) {
    final box = chipCtx.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(chipCtx).overlay!.context.findRenderObject() as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<String>(
      context: chipCtx,
      position: rect,
      elevation: 8,
      color: isDark ? const Color(0xFF1E2330) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      items: _allStatuses.where((s) => s != _currentStatus).map((s) {
        final sc = _statusColor(s, cs);
        final sbg = isDark ? _statusBgDark(s) : _statusBg(s);
        return PopupMenuItem<String>(
          value: s,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sbg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _statusLabel(s).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: sc,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).then((sel) {
      if (sel == null) return;
      setState(() => _currentStatus = sel);
      widget.taskVm.updateTaskStatus(taskId: widget.task.id, status: sel);
    });
  }

  Future<void> _pickAssignee(BuildContext ctx, List<UserModel> members) async {
    final init = _selectedAssigneeUid != null
        ? {_selectedAssigneeUid!}
        : <String>{};
    final result = await showDialog<Set<String>>(
      context: ctx,
      builder: (_) => MemberSelectDialog(
        initialSelected: init,
        singleSelect: true,
        hideCurrentUser: false,
        overrideUsers: members,
      ),
    );
    if (result == null) return;
    setState(() => _selectedAssigneeUid = result.isEmpty ? null : result.first);
    widget.taskVm.updateTask(
      taskId: widget.task.id,
      assignedUserUid: result.isEmpty ? null : result.first,
      unassign: result.isEmpty,
    );
  }

  /// Opens the move-to-project bottom sheet.
  Future<void> _openMoveSheet(BuildContext ctx) async {
    final projectVm = ctx.read<ProjectViewModel>();
    final authVm = ctx.read<AuthViewModel>();
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final cs = Theme.of(ctx).colorScheme;

    // Only show projects the user is a member of, excluding the current one
    final otherProjects = projectVm.projects
        .where(
          (p) =>
              p.id != widget.task.projectId && p.members.contains(authVm.uid),
        )
        .toList();

    if (otherProjects.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text(
            'No other projects available to move this task to.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _MoveProjectSheet(
        otherProjects: otherProjects,
        currentAssigneeUid: _selectedAssigneeUid,
        isDark: isDark,
        cs: cs,
        onConfirm: (targetProject) {
          Navigator.pop(sheetCtx);
          widget.taskVm.moveTask(
            taskId: widget.task.id,
            targetProjectId: targetProject.id,
          );
          // Close the task dialog too — task is gone from this board
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _saveAll(BuildContext ctx) async {
    if (_editingTitle) _commitTitle();
    if (_editingDesc) _commitDesc();
    if (_editingPoints) _commitPoints();

    final title = _pendingTitle.trim();
    final desc = _pendingDesc.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Title cannot be empty'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final newPts = _parsedPts;
    final oldPts = widget.task.storyPoints;
    double? ptsToSend;
    if (newPts == null && oldPts != null) {
      ptsToSend = 0.0;
    } else if (newPts != null && newPts != oldPts) {
      ptsToSend = newPts;
    }

    widget.taskVm.updateTask(
      taskId: widget.task.id,
      title: title,
      description: desc,
      assignedUserUid: _selectedAssigneeUid != widget.task.assignedUserUid
          ? _selectedAssigneeUid
          : null,
      unassign: false,
      storyPoints: ptsToSend,
    );

    setState(() {
      _saved = true;
      _savedTitle = title;
      _savedDesc = desc;
      _savedPoints = _pointsCtrl.text.trim();
      _savedAssigneeUid = _selectedAssigneeUid;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (ctx.mounted) Navigator.pop(ctx);
  }

  late String _savedTitle;
  late String _savedDesc;
  late String _savedPoints;
  late String? _savedAssigneeUid;

  bool get _hasChanges =>
      _pendingTitle.trim() != _savedTitle ||
      _pendingDesc.trim() != _savedDesc ||
      _pointsCtrl.text.trim() != _savedPoints ||
      _selectedAssigneeUid != _savedAssigneeUid;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVm = context.watch<AuthViewModel>();
    final userVm = context.watch<UserViewModel>();

    final isEditor =
        authVm.uid == widget.project.creatorUid ||
        authVm.uid == widget.task.createdByUid ||
        authVm.uid == widget.task.assignedUserUid;

    // Only project creator or task creator can move
    final canMove =
        authVm.uid == widget.project.creatorUid ||
        authVm.uid == widget.task.createdByUid;

    final members = userVm.allUsers
        .where((u) => widget.project.members.contains(u.uid))
        .toList();

    final surface = isDark ? const Color(0xFF161B27) : Colors.white;
    final sidebar = isDark ? const Color(0xFF1A2035) : const Color(0xFFF7F8FA);
    final border = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final labelColor = isDark
        ? const Color(0xFF8C96A8)
        : const Color(0xFF6B778C);
    final textColor = isDark
        ? const Color(0xFFDDE3EE)
        : const Color(0xFF172B4D);
    final mutedColor = isDark
        ? const Color(0xFF4A5568)
        : const Color(0xFFB3BAC5);
    final hoverColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.025);
    final statusColor = _statusColor(_currentStatus, cs);
    final statusBg = isDark
        ? _statusBgDark(_currentStatus)
        : _statusBg(_currentStatus);

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isMobile = screenW < 600;

    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(_anim),
        child: Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: isMobile
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 12),
            side: BorderSide(color: border),
          ),
          elevation: 24,
          child: isMobile
              ? _buildMobile(
                  context,
                  cs,
                  isDark,
                  isEditor,
                  canMove,
                  members,
                  surface,
                  sidebar,
                  border,
                  labelColor,
                  textColor,
                  mutedColor,
                  hoverColor,
                  statusColor,
                  statusBg,
                  screenW,
                  screenH,
                )
              : SizedBox(
                  width: 860,
                  height: 580,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── LEFT panel ──────────────────────────────
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _topBar(
                              context,
                              cs,
                              isDark,
                              border,
                              labelColor,
                              isEditor,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  24,
                                  28,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _inlineTitle(
                                      context,
                                      isDark,
                                      textColor,
                                      mutedColor,
                                      hoverColor,
                                      isEditor,
                                    ),
                                    const SizedBox(height: 16),
                                    _fieldLabel('Description', labelColor),
                                    const SizedBox(height: 8),
                                    _inlineDesc(
                                      context,
                                      isDark,
                                      textColor,
                                      mutedColor,
                                      hoverColor,
                                      isEditor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _footer(
                              context,
                              cs,
                              isDark,
                              border,
                              textColor,
                              isEditor,
                            ),
                          ],
                        ),
                      ),

                      // ── DIVIDER ──────────────────────────────────
                      VerticalDivider(width: 1, thickness: 1, color: border),

                      // ── RIGHT sidebar ────────────────────────────
                      SizedBox(
                        width: 240,
                        child: Container(
                          decoration: BoxDecoration(
                            color: sidebar,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sidebarGroup(
                                  'STATUS',
                                  labelColor,
                                  child: Builder(
                                    builder: (chipCtx) => GestureDetector(
                                      onTap:
                                          isEditor && _currentStatus != 'DONE'
                                          ? () => _openStatusMenu(
                                              chipCtx,
                                              cs,
                                              isDark,
                                            )
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _statusLabel(
                                                _currentStatus,
                                              ).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            if (isEditor &&
                                                _currentStatus != 'DONE') ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.expand_more_rounded,
                                                size: 14,
                                                color: statusColor,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _sidebarDivider(border),
                                _sidebarGroup(
                                  'ASSIGNEE',
                                  labelColor,
                                  child: InkWell(
                                    onTap: isEditor
                                        ? () => _pickAssignee(context, members)
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    hoverColor: hoverColor,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          _avatar(
                                            context,
                                            _selectedAssigneeUid,
                                            cs,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _assigneeName(
                                                context,
                                                _selectedAssigneeUid,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          if (isEditor)
                                            Icon(
                                              Icons.unfold_more_rounded,
                                              size: 14,
                                              color: labelColor,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                _sidebarDivider(border),
                                _sidebarGroup(
                                  'STORY POINTS',
                                  labelColor,
                                  child: _inlinePoints(
                                    context,
                                    isDark,
                                    textColor,
                                    labelColor,
                                    mutedColor,
                                    hoverColor,
                                    cs,
                                    isEditor,
                                  ),
                                ),
                                _sidebarDivider(border),
                                _sidebarGroup(
                                  'REPORTER',
                                  labelColor,
                                  child: _reporterRow(context, cs, textColor),
                                ),
                                _sidebarDivider(border),
                                _sidebarGroup(
                                  'SPRINT',
                                  labelColor,
                                  child: _sidebarValue('Current', textColor),
                                ),
                                _sidebarDivider(border),
                                // ── PROJECT (tappable if canMove) ────────────
                                _sidebarGroup(
                                  'PROJECT',
                                  labelColor,
                                  child: InkWell(
                                    onTap: canMove
                                        ? () => _openMoveSheet(context)
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    hoverColor: canMove
                                        ? hoverColor
                                        : Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.folder_outlined,
                                            size: 13,
                                            color: labelColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              widget.project.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          if (canMove)
                                            Icon(
                                              Icons.drive_file_move_outlined,
                                              size: 14,
                                              color: labelColor,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildMobile(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    bool isEditor,
    bool canMove,
    List<UserModel> members,
    Color surface,
    Color sidebar,
    Color border,
    Color labelColor,
    Color textColor,
    Color mutedColor,
    Color hoverColor,
    Color statusColor,
    Color statusBg,
    double screenW,
    double screenH,
  ) {
    return SizedBox(
      width: screenW,
      height: screenH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context, cs, isDark, border, labelColor, isEditor),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _inlineTitle(
                      context,
                      isDark,
                      textColor,
                      mutedColor,
                      hoverColor,
                      isEditor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sidebar,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _mobileMetaRow(
                            left: _mobileMetaCell(
                              label: 'STATUS',
                              labelColor: labelColor,
                              child: Builder(
                                builder: (chipCtx) => GestureDetector(
                                  onTap: isEditor && _currentStatus != 'DONE'
                                      ? () =>
                                            _openStatusMenu(chipCtx, cs, isDark)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _statusLabel(
                                            _currentStatus,
                                          ).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        if (isEditor &&
                                            _currentStatus != 'DONE') ...[
                                          const SizedBox(width: 3),
                                          Icon(
                                            Icons.expand_more_rounded,
                                            size: 13,
                                            color: statusColor,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            right: _mobileMetaCell(
                              label: 'ASSIGNEE',
                              labelColor: labelColor,
                              child: InkWell(
                                onTap: isEditor
                                    ? () => _pickAssignee(context, members)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                hoverColor: hoverColor,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _avatar(
                                      context,
                                      _selectedAssigneeUid,
                                      cs,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _assigneeName(
                                          context,
                                          _selectedAssigneeUid,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (isEditor) ...[
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.unfold_more_rounded,
                                        size: 13,
                                        color: labelColor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            border: border,
                          ),
                          Divider(height: 1, thickness: 1, color: border),
                          _mobileMetaRow(
                            left: _mobileMetaCell(
                              label: 'STORY POINTS',
                              labelColor: labelColor,
                              child: _inlinePoints(
                                context,
                                isDark,
                                textColor,
                                labelColor,
                                mutedColor,
                                hoverColor,
                                cs,
                                isEditor,
                              ),
                            ),
                            right: _mobileMetaCell(
                              label: 'REPORTER',
                              labelColor: labelColor,
                              child: _reporterRow(context, cs, textColor),
                            ),
                            border: border,
                          ),
                          Divider(height: 1, thickness: 1, color: border),
                          _mobileMetaRow(
                            left: _mobileMetaCell(
                              label: 'SPRINT',
                              labelColor: labelColor,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.loop_rounded,
                                    size: 13,
                                    color: labelColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            right: _mobileMetaCell(
                              label: 'PROJECT',
                              labelColor: labelColor,
                              child: InkWell(
                                onTap: canMove
                                    ? () => _openMoveSheet(context)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      size: 13,
                                      color: labelColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        widget.project.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (canMove) ...[
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.drive_file_move_outlined,
                                        size: 13,
                                        color: labelColor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            border: border,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.subject_rounded,
                              size: 15,
                              color: labelColor,
                            ),
                            const SizedBox(width: 6),
                            _fieldLabel('Description', labelColor),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _inlineDesc(
                          context,
                          isDark,
                          textColor,
                          mutedColor,
                          hoverColor,
                          isEditor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _footer(context, cs, isDark, border, textColor, isEditor),
        ],
      ),
    );
  }

  Widget _mobileMetaRow({
    required Widget left,
    required Widget right,
    required Color border,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          VerticalDivider(width: 1, thickness: 1, color: border),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _mobileMetaCell({
    required String label,
    required Color labelColor,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _mobileMetaLabel(label, labelColor),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _mobileMetaLabel(String text, Color color) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: color,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════════
  // SHARED helpers
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _topBar(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    Color border,
    Color labelColor,
    bool isEditor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded, size: 11, color: cs.primary),
                const SizedBox(width: 3),
                Text(
                  'TICKET-${widget.task.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: border),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.project.name,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: 'View activity history',
            child: InkWell(
              onTap: () => showTaskHistorySheet(
                context: context,
                taskId: widget.task.id,
                taskTitle: widget.task.title,
                repo: context.read<AppRepository>(),
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.history_rounded, size: 18, color: labelColor),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 18, color: labelColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineTitle(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color hoverColor,
    bool isEditor,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (_editingTitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            focusNode: _titleFocus,
            autofocus: true,
            maxLines: null,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.3,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _commitTitle(),
            cursorColor: cs.primary,
            decoration: _inlineDecoration(isDark, cs),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _smallButton(
                label: 'Cancel',
                onTap: () {
                  _titleCtrl.text = _pendingTitle;
                  setState(() => _editingTitle = false);
                },
                isDark: isDark,
                textColor: mutedColor,
              ),
              const SizedBox(width: 8),
              _smallButton(
                label: 'Save',
                onTap: _commitTitle,
                isDark: isDark,
                textColor: cs.primary,
                bordered: true,
                borderColor: cs.primary,
              ),
            ],
          ),
        ],
      );
    }
    return InkWell(
      onTap: isEditor ? () => setState(() => _editingTitle = true) : null,
      borderRadius: BorderRadius.circular(6),
      hoverColor: isEditor ? hoverColor : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            _pendingTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineDesc(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color hoverColor,
    bool isEditor,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (_editingDesc) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _descCtrl,
            focusNode: _descFocus,
            autofocus: true,
            maxLines: null,
            minLines: 5,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.6),
            cursorColor: cs.primary,
            decoration: _inlineDecoration(
              isDark,
              cs,
              hint: 'Add a description…',
              mutedColor: mutedColor,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _smallButton(
                label: 'Cancel',
                onTap: () {
                  _descCtrl.text = _pendingDesc;
                  setState(() => _editingDesc = false);
                },
                isDark: isDark,
                textColor: mutedColor,
              ),
              const SizedBox(width: 8),
              _smallButton(
                label: 'Save',
                onTap: _commitDesc,
                isDark: isDark,
                textColor: cs.primary,
                bordered: true,
                borderColor: cs.primary,
              ),
            ],
          ),
        ],
      );
    }

    final isEmpty = _pendingDesc.isEmpty;
    return InkWell(
      onTap: isEditor ? () => setState(() => _editingDesc = true) : null,
      borderRadius: BorderRadius.circular(6),
      hoverColor: isEditor ? hoverColor : Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          isEmpty
              ? (isEditor ? 'Click to add a description…' : 'No description')
              : _pendingDesc,
          style: TextStyle(
            fontSize: 14,
            color: isEmpty ? mutedColor : textColor,
            height: 1.65,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _inlinePoints(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color mutedColor,
    Color hoverColor,
    ColorScheme cs,
    bool isEditor,
  ) {
    if (_editingPoints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: TextField(
              controller: _pointsCtrl,
              focusNode: _pointsFocus,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: TextStyle(fontSize: 13, color: textColor),
              cursorColor: cs.primary,
              decoration: _inlineDecoration(
                isDark,
                cs,
                hint: 'e.g. 3',
                mutedColor: mutedColor,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _commitPoints(),
            ),
          ),
          if (_hoursPreview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '1 pt = ${TaskModel.hoursPerPoint}h  •  $_hoursPreview',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ],
        ],
      );
    }

    final pts = widget.task.storyPoints;
    final hasPoints = pts != null && pts > 0;

    return InkWell(
      onTap: isEditor ? () => setState(() => _editingPoints = true) : null,
      borderRadius: BorderRadius.circular(6),
      hoverColor: isEditor ? hoverColor : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: hasPoints
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_ptsStr(pts)} ${pts == 1.0 ? "PT" : "PTS"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: 1,
                    height: 11,
                    color: labelColor.withOpacity(0.35),
                  ),
                  Text(
                    widget.task.hoursLabel,
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
                ],
              )
            : Text(
                isEditor ? 'Click to estimate…' : 'Not estimated',
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
      ),
    );
  }

  Widget _reporterRow(BuildContext ctx, ColorScheme cs, Color textColor) {
    final creatorUid = widget.task.createdByUid;
    final creatorUser = ctx.read<UserViewModel>().allUsers.firstWhereOrNull(
      (u) => u.uid == creatorUid,
    );
    final name = creatorUser != null
        ? (creatorUid == ctx.read<AuthViewModel>().uid
              ? 'You'
              : '${creatorUser.firstName} ${creatorUser.lastName}'.trim())
        : 'Unknown';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _avatar(ctx, creatorUid, cs, size: 22, nameOverride: name),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _footer(
    BuildContext ctx,
    ColorScheme cs,
    bool isDark,
    Color border,
    Color textColor,
    bool isEditor,
  ) {
    final dimText = isDark ? Colors.white54 : const Color(0xFF6B778C);

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEditor && _hasChanges) ...[
            TextButton(
              onPressed: () => setState(() {
                _pendingTitle = _savedTitle;
                _pendingDesc = _savedDesc;
                _titleCtrl.text = _savedTitle;
                _descCtrl.text = _savedDesc;
                _pointsCtrl.text = _savedPoints;
                _selectedAssigneeUid = _savedAssigneeUid;
                _editingTitle = false;
                _editingDesc = false;
                _editingPoints = false;
              }),
              style: TextButton.styleFrom(
                foregroundColor: dimText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Discard',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _saved ? const Color(0xFF36B37E) : cs.primary,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: (_saved ? const Color(0xFF36B37E) : cs.primary)
                        .withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _saveAll(ctx),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _saved ? Icons.check_rounded : Icons.save_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _saved ? 'Saved!' : 'Save changes',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: dimText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inlineDecoration(
    bool isDark,
    ColorScheme cs, {
    String? hint,
    Color? mutedColor,
  }) {
    final fill = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.025);
    final borderSide = BorderSide(color: cs.primary.withOpacity(0.45));
    final focusedBorderSide = BorderSide(color: cs.primary, width: 1.5);
    return InputDecoration(
      hintText: hint,
      hintStyle: hint != null
          ? TextStyle(color: mutedColor, fontSize: 13)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: focusedBorderSide,
      ),
    );
  }

  Widget _smallButton({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    bool bordered = false,
    Color? borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: bordered && borderColor != null
              ? Border.all(color: borderColor)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _sidebarDivider(Color border) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Divider(height: 1, thickness: 1, color: border),
  );

  Widget _sidebarGroup(
    String label,
    Color labelColor, {
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _fieldLabel(String text, Color color) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: color,
    ),
  );

  Widget _sidebarValue(String text, Color textColor) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
  );

  Widget _avatar(
    BuildContext ctx,
    String? uid,
    ColorScheme cs, {
    double size = 26,
    String? nameOverride,
  }) {
    String name;
    if (nameOverride != null) {
      name = nameOverride;
    } else {
      name = _assigneeName(ctx, uid);
    }
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
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: cs.onPrimary,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOVE PROJECT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _MoveProjectSheet extends StatefulWidget {
  final List<ProjectModel> otherProjects;
  final String? currentAssigneeUid;
  final bool isDark;
  final ColorScheme cs;
  final void Function(ProjectModel) onConfirm;

  const _MoveProjectSheet({
    required this.otherProjects,
    required this.currentAssigneeUid,
    required this.isDark,
    required this.cs,
    required this.onConfirm,
  });

  @override
  State<_MoveProjectSheet> createState() => _MoveProjectSheetState();
}

class _MoveProjectSheetState extends State<_MoveProjectSheet> {
  ProjectModel? _selected;

  bool get _assigneeWillBeDropped =>
      _selected != null &&
      widget.currentAssigneeUid != null &&
      !_selected!.members.contains(widget.currentAssigneeUid);

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? const Color(0xFF161B27) : Colors.white;
    final labelColor = widget.isDark
        ? const Color(0xFF8C96A8)
        : const Color(0xFF6B778C);
    final textColor = widget.isDark
        ? const Color(0xFFDDE3EE)
        : const Color(0xFF172B4D);
    final border = widget.isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final itemBg = widget.isDark
        ? const Color(0xFF1A2035)
        : const Color(0xFFF7F8FA);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: border)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──────────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Icon(
                  Icons.drive_file_move_outlined,
                  size: 18,
                  color: widget.cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Move to project',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text(
              'Task will be moved to TODO and status reset.',
              style: TextStyle(fontSize: 12, color: labelColor),
            ),
          ),

          // ── Warning banner (assignee will be dropped) ────────────────────
          if (_assigneeWillBeDropped)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFF8B00,
                  ).withOpacity(widget.isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF8B00).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFFF8B00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The current assignee is not a member of this project and will be unassigned.',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? const Color(0xFFFFB84D)
                              : const Color(0xFF7A4000),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Project list ─────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.38,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.otherProjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final project = widget.otherProjects[i];
                final isSelected = _selected?.id == project.id;

                return InkWell(
                  onTap: () => setState(() => _selected = project),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.cs.primary.withOpacity(
                              widget.isDark ? 0.18 : 0.08,
                            )
                          : itemBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? widget.cs.primary.withOpacity(0.5)
                            : border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.folder_rounded,
                            size: 16,
                            color: widget.cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${project.members.length} member${project.members.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? widget.cs.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? widget.cs.primary
                                  : labelColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Confirm button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: ElevatedButton(
              onPressed: _selected != null
                  ? () => widget.onConfirm(_selected!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.cs.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: widget.isDark
                    ? Colors.white12
                    : Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                _selected == null
                    ? 'Select a project'
                    : 'Move to "${_selected!.name}"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
