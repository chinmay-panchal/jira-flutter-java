import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jira_flutter_java/Core/theme/theme_provider.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/project_details_dialog.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/task_details_dialog.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:jira_flutter_java/Core/theme/theme_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../DashboardViewModel/task_view_model.dart';
import '../DashboardModel/task_model.dart';
import 'create_todo_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final int projectId;

  const DashboardScreen({super.key, required this.projectId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageController;

  bool _isAutoScrolling = false;
  bool _isDragging = false;
  bool _shouldTrackPageChanges = true;
  DateTime? _edgeHoverStart;
  bool _initialPageSet = false;
  int? _currentPage;

  // final sections = const [
  //   ('TODO', Colors.blue),
  //   ('IN_PROGRESS', Colors.orange),
  //   ('QA', Colors.red),
  //   ('DONE', Colors.green),
  // ];

  final sections = const ['TODO', 'IN_PROGRESS', 'QA', 'DONE'];

  // In DashboardScreen, update the initState:
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(_onPageControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<TaskViewModel>();
      final userVm = context.read<UserViewModel>(); // Add this

      if (vm.tasks.isEmpty) {
        await vm.loadTasks(widget.projectId);
        // Load users after loading tasks
        await userVm.loadProjectMembers(widget.projectId); // Add this
      }

      if (mounted && !kIsWeb) {
        _setInitialPage(vm);
      }
    });
  }

  String _getAssigneeName(BuildContext context, String? uid) {
    if (uid == null) return 'Unassigned';

    final userVm = context.watch<UserViewModel>();

    // If users are still loading, show loading indicator
    if (userVm.isLoading && userVm.users.isEmpty) {
      return 'Loading...';
    }

    final user = userVm.users.firstWhereOrNull((u) => u.uid == uid);

    if (user == null) {
      // User not found - might need to load project members
      return 'Unknown';
    }

    return '${user.firstName} ${user.lastName}'.trim();
  }

  Widget _taskCard(
    BuildContext context,
    TaskModel task, {
    Color? accentColor,
    bool isDragging = false,
  }) {
    final assigneeName = _getAssigneeName(context, task.assignedUserUid);

    return InkWell(
      onTap: isDragging
          ? null
          : () {
              showDialog(
                context: context,
                builder: (_) => TaskDetailDialog(task: task),
              );
            },
      borderRadius: BorderRadius.circular(10),
      child: Card(
        elevation: isDragging ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket ID
              Text(
                'TICKET-${task.id}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor ?? Colors.grey,
                ),
              ),
              const SizedBox(height: 4),

              // Title + Assignee (if no description)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.description.isEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (accentColor ??
                                    Theme.of(context).colorScheme.primary)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            assigneeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Description + Assignee (if description exists)
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (accentColor ??
                                    Theme.of(context).colorScheme.primary)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            assigneeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onPageControllerChange() {
    if (!_shouldTrackPageChanges) return;

    if (_pageController.hasClients && _pageController.page != null) {
      final newPage = _pageController.page!.round();
      if (_currentPage != newPage) {
        _currentPage = newPage;
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageControllerChange);
    _pageController.dispose();
    super.dispose();
  }

  void _setInitialPage(TaskViewModel vm) {
    if (_initialPageSet) return;
    if (!_pageController.hasClients) return;

    for (int i = 0; i < sections.length; i++) {
      final status = sections[i];
      final count = vm.byStatus(status).length;

      if (count > 0) {
        _pageController.jumpToPage(i);
        _currentPage = i;
        _initialPageSet = true;
        return;
      }
    }

    _pageController.jumpToPage(0);
    _currentPage = 0;
    _initialPageSet = true;
  }

  bool _isValidTransition(String from, String to) {
    if (from == to) return false;

    bool isValid = false;
    if (from == 'TODO') {
      isValid = to == 'IN_PROGRESS' || to == 'QA';
    } else if (from == 'IN_PROGRESS') {
      isValid = to == 'TODO' || to == 'QA';
    } else if (from == 'QA') {
      isValid = to == 'IN_PROGRESS' || to == 'TODO' || to == 'DONE';
    }
    return isValid;
  }

  Future<void> _handleAutoScroll(Offset position, BuildContext context) async {
    if (_isAutoScrolling || !_isDragging) return;

    final width = MediaQuery.of(context).size.width;
    const edgeSize = 100;
    const hoverDelay = Duration(milliseconds: 200);

    final isLeft = position.dx < edgeSize;
    final isRight = position.dx > width - edgeSize;

    if (!isLeft && !isRight) {
      _edgeHoverStart = null;
      return;
    }

    _edgeHoverStart ??= DateTime.now();

    if (DateTime.now().difference(_edgeHoverStart!) < hoverDelay) return;
    if (_pageController.page == null) return;

    final currentPage = _pageController.page!.round();

    if (isLeft && currentPage > 0) {
      _isAutoScrolling = true;
      _edgeHoverStart = null;
      await _pageController.animateToPage(
        currentPage - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _isAutoScrolling = false;
    } else if (isRight && currentPage < sections.length - 1) {
      _isAutoScrolling = true;
      _edgeHoverStart = null;
      await _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _isAutoScrolling = false;
    }
  }

  void _showAccessRevokedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (alertContext) => AlertDialog(
        title: const Text('Access removed'),
        content: const Text('You are no longer a member of this project.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(alertContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext context, String status, TaskViewModel vm) {
    final color = Theme.of(context).colorScheme.primary;

    final tasks = vm.byStatus(status);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DragTarget<TaskModel>(
          onWillAccept: (task) {
            return task != null && _isValidTransition(task.status, status);
          },
          onAccept: (task) async {
            _isDragging = false;
            _edgeHoverStart = null;
            _shouldTrackPageChanges = false;

            try {
              await vm.updateTaskStatus(taskId: task.id, status: status);
            } catch (_) {
              if (mounted) {
                _showAccessRevokedDialog();
              }
              return;
            }

            _shouldTrackPageChanges = true;
          },
          onLeave: (_) {
            _edgeHoverStart = null;
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isHovering ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: isHovering ? Border.all(color: color, width: 2) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: tasks.isEmpty
                        ? Center(
                            child: Text(
                              'No tasks',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (_, i) {
                              final task = tasks[i];

                              return Draggable<TaskModel>(
                                data: task,
                                onDragStarted: () => _isDragging = true,
                                onDragEnd: (_) {
                                  _isDragging = false;
                                  _edgeHoverStart = null;
                                },
                                onDraggableCanceled: (_, __) {
                                  _isDragging = false;
                                  _edgeHoverStart = null;
                                },

                                // 👇 Drag preview
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: kIsWeb
                                        ? MediaQuery.of(context).size.width /
                                                  4 -
                                              40
                                        : 260,
                                    child: _taskCard(
                                      context,
                                      task,
                                      accentColor: color,
                                      isDragging: true,
                                    ),
                                  ),
                                ),

                                // 👇 While dragging
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _taskCard(context, task),
                                ),

                                // 👇 Normal state
                                child: _taskCard(context, task),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!_initialPageSet && vm.tasks.isNotEmpty && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setInitialPage(vm);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Consumer<ProjectViewModel>(
          builder: (context, projectVm, _) {
            final project = projectVm.byId(widget.projectId);
            return Text(project?.name ?? 'Dashboard');
          },
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Project details',
            icon: const Icon(Icons.work_outline),
            onPressed: () async {
              final userVm = context.read<UserViewModel>();

              try {
                await userVm.loadUsers();
                await userVm.loadProjectMembers(widget.projectId);

                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (_) =>
                      ProjectDetailsDialog(projectId: widget.projectId),
                );
              } catch (_) {
                if (!mounted) return;
                _showAccessRevokedDialog();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: const Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pop(context);
                await context.read<AuthViewModel>().logout();
              },
            ),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb
          // WEB: Show all columns side-by-side
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections.map((status) {
                  return _buildColumn(context, status, vm);
                }).toList(),
              ),
            )
          // MOBILE: Use PageView with scrolling
          : Listener(
              onPointerMove: (e) => _handleAutoScroll(e.position, context),
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                padEnds: false,
                itemCount: sections.length,
                onPageChanged: (page) {
                  _currentPage = page;
                },
                itemBuilder: (_, index) {
                  final status = sections[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildColumn(context, status, vm),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final taskVm = context.read<TaskViewModel>();
          final userVm = context.read<UserViewModel>();

          try {
            await userVm.loadProjectMembers(widget.projectId);

            if (!mounted) return;
            showDialog(
              context: context,
              builder: (_) =>
                  CreateTodoDialog(projectId: widget.projectId, taskVm: taskVm),
            );
          } catch (_) {
            if (!mounted) return;
            _showAccessRevokedDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
