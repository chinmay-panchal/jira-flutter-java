import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/theme/theme_provider.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/project_details_dialog.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:provider/provider.dart';
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

  // This flag ensures we don't listen to page changes while we are programmatically updating things
  bool _shouldTrackPageChanges = true;
  DateTime? _edgeHoverStart;

  // CRITICAL: This must only be false on creation.
  bool _initialPageSet = false;
  int? _currentPage;

  final sections = const [
    ('TODO', Colors.blue),
    ('IN_PROGRESS', Colors.orange),
    ('QA', Colors.red),
    ('DONE', Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    // Keep viewportFraction if you want the "peek" effect
    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(_onPageControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<TaskViewModel>();
      // Only load if empty or if you strictly need fresh data on enter
      if (vm.tasks.isEmpty) {
        await vm.loadTasks(widget.projectId);
      }

      // Attempt to set initial page after load
      if (mounted) {
        _setInitialPage(vm);
      }
    });
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
    // 1. If we have already set the initial page, STOP.
    // This prevents resets on subsequent updates (like drag and drop).
    if (_initialPageSet) return;

    // 2. If controller isn't ready, we can't jump anyway.
    if (!_pageController.hasClients) return;

    // Logic to find the first non-empty page
    for (int i = 0; i < sections.length; i++) {
      final status = sections[i].$1;
      final count = vm.byStatus(status).length;

      if (count > 0) {
        _pageController.jumpToPage(i);
        _currentPage = i;
        _initialPageSet = true; // MARK AS SET
        return;
      }
    }

    // Default fallback
    _pageController.jumpToPage(0);
    _currentPage = 0;
    _initialPageSet = true; // MARK AS SET
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
              Navigator.of(alertContext).pop(); // Pop alert
              Navigator.of(context).pop(); // Pop dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskViewModel>();

    // CRITICAL CHANGE:
    // We moved the _setInitialPage logic mostly to initState/postFrameCallback.
    // However, if tasks were empty initially and just arrived (API lag), we check here.
    // BUT we ensure _initialPageSet is respected so we don't jump again later.
    if (!_initialPageSet && vm.tasks.isNotEmpty) {
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

              // UPFRONT ACCESS CHECK - verify user still has access before showing project details
              try {
                await userVm.loadUsers();
                await userVm.loadProjectMembers(widget.projectId);

                // If we reach here, user has access - show dialog
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (_) =>
                      ProjectDetailsDialog(projectId: widget.projectId),
                );
              } catch (_) {
                // User no longer has access - show error and go back
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
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
              ),
              child: Center(
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

            /// 🌗 Theme toggle
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Theme'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                );
              },
            ),

            const Divider(),

            /// 🚪 Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                Navigator.pop(context); // Pop dashboard screen
                await context.read<AuthViewModel>().logout();
              },
            ),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Listener(
              onPointerMove: (e) => _handleAutoScroll(e.position, context),
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                padEnds: false, // Removes automatic padding at start/end
                itemCount: sections.length,
                onPageChanged: (page) {
                  // Standard page tracking
                  _currentPage = page;
                },
                itemBuilder: (_, index) {
                  final status = sections[index].$1;
                  final color = sections[index].$2;
                  final tasks = vm.byStatus(status);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: DragTarget<TaskModel>(
                      onWillAccept: (task) {
                        return task != null &&
                            _isValidTransition(task.status, status);
                      },
                      onAccept: (task) async {
                        // 1. Stop dragging flags immediately
                        _isDragging = false;
                        _edgeHoverStart = null;

                        // 2. Stop tracking page changes temporarily
                        // This prevents the controller listener from getting confused
                        // if the list rebuild causes a slight scroll jitter.
                        _shouldTrackPageChanges = false;

                        // 3. Capture the current page index BEFORE update
                        // (Though we are relying on PageView not rebuilding the controller)
                        final pageBeforeUpdate = _currentPage;

                        // 4. Update the data
                        try {
                          await vm.updateTaskStatus(
                            taskId: task.id,
                            status: status,
                          );
                        } catch (_) {
                          // User lost access during drag
                          if (mounted) {
                            _showAccessRevokedDialog();
                          }
                          return;
                        }

                        // 5. Re-enable tracking
                        _shouldTrackPageChanges = true;

                        // 6. FORCE stay on the current page if needed
                        // Usually not needed if _initialPageSet is correct, but safe to have.
                        if (pageBeforeUpdate != null &&
                            _pageController.hasClients) {
                          // If the update caused a jump, this snaps it back,
                          // but ideally, the UI just rebuilds in place.
                          if (_pageController.page?.round() !=
                              pageBeforeUpdate) {
                            _pageController.jumpToPage(pageBeforeUpdate);
                          }
                        }
                      },
                      onLeave: (_) {
                        _edgeHoverStart = null;
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(isHovering ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: isHovering
                                ? Border.all(color: color, width: 2)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                            onDragStarted: () {
                                              _isDragging = true;
                                            },
                                            onDragEnd: (details) {
                                              _isDragging = false;
                                              _edgeHoverStart = null;
                                            },
                                            onDraggableCanceled: (_, __) {
                                              _isDragging = false;
                                              _edgeHoverStart = null;
                                            },
                                            feedback: Material(
                                              elevation: 8,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 240,
                                                child: Card(
                                                  color: color.withOpacity(0.9),
                                                  child: ListTile(
                                                    title: Text(
                                                      task.title,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.3,
                                              child: Card(
                                                child: ListTile(
                                                  title: Text(task.title),
                                                ),
                                              ),
                                            ),
                                            child: Card(
                                              elevation: 2,
                                              child: ListTile(
                                                title: Text(task.title),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final taskVm = context.read<TaskViewModel>();
          final userVm = context.read<UserViewModel>();

          // UPFRONT ACCESS CHECK - verify user still has access before showing dialog
          try {
            await userVm.loadProjectMembers(widget.projectId);

            // If we reach here, user has access - show dialog
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (_) =>
                  CreateTodoDialog(projectId: widget.projectId, taskVm: taskVm),
            );
          } catch (_) {
            // User no longer has access - show error and go back
            if (!mounted) return;
            _showAccessRevokedDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
