import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/theme/theme_provider.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/project_details_dialog.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:provider/provider.dart';

import '../DashboardViewModel/task_view_model.dart';
import '../DashboardModel/task_model.dart';
import 'create_todo_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final int projectId;

  const DashboardScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskViewModel(context.read<AppRepository>()),
      child: _DashboardBody(projectId: projectId),
    );
  }
}

/* -------------------------------------------------------------------------- */

class _DashboardBody extends StatefulWidget {
  final int projectId;

  const _DashboardBody({required this.projectId});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  late final PageController _pageController;

  bool _isAutoScrolling = false;
  bool _isDragging = false;
  bool _shouldTrackPageChanges = true;
  DateTime? _edgeHoverStart;

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

    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(_onPageControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<TaskViewModel>();
      await vm.loadTasks(widget.projectId);

      if (mounted) {
        _setInitialPage(vm);
      }
    });
  }

  void _onPageControllerChange() {
    if (!_shouldTrackPageChanges) return;

    if (_pageController.hasClients && _pageController.page != null) {
      _currentPage = _pageController.page!.round();
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
      if (vm.byStatus(sections[i].$1).isNotEmpty) {
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

    if (from == 'TODO') return to == 'IN_PROGRESS' || to == 'QA';
    if (from == 'IN_PROGRESS') return to == 'TODO' || to == 'QA';
    if (from == 'QA')
      return to == 'IN_PROGRESS' || to == 'TODO' || to == 'DONE';

    return false;
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

    final page = _pageController.page!.round();

    _isAutoScrolling = true;
    _edgeHoverStart = null;

    await _pageController.animateToPage(
      isLeft ? page - 1 : page + 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    _isAutoScrolling = false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskViewModel>();

    if (!_initialPageSet && vm.tasks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setInitialPage(vm);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
              await context.read<UserViewModel>().loadUsers();

              showDialog(
                context: context,
                builder: (_) =>
                    ProjectDetailsDialog(projectId: widget.projectId),
              );
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

            Consumer<ThemeProvider>(
              builder: (_, themeProvider, __) => ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Theme'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
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
                itemCount: sections.length,
                itemBuilder: (_, index) {
                  final status = sections[index].$1;
                  final color = sections[index].$2;
                  final tasks = vm.byStatus(status);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: DragTarget<TaskModel>(
                      onWillAccept: (task) =>
                          task != null &&
                          _isValidTransition(task.status, status),
                      onAccept: (task) async {
                        _isDragging = false;
                        _edgeHoverStart = null;
                        _shouldTrackPageChanges = false;

                        final pageBefore = _currentPage;

                        await vm.updateTaskStatus(
                          taskId: task.id,
                          status: status,
                        );

                        _shouldTrackPageChanges = true;

                        if (pageBefore != null && _pageController.hasClients) {
                          _pageController.jumpToPage(pageBefore);
                        }
                      },
                      builder: (_, candidate, __) {
                        final hovering = candidate.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(hovering ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: hovering
                                ? Border.all(color: color, width: 2)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: tasks.isEmpty
                                    ? const Center(child: Text('No tasks'))
                                    : ListView.builder(
                                        itemCount: tasks.length,
                                        itemBuilder: (_, i) {
                                          final task = tasks[i];

                                          return Draggable<TaskModel>(
                                            data: task,
                                            onDragStarted: () =>
                                                _isDragging = true,
                                            onDragEnd: (_) {
                                              _isDragging = false;
                                              _edgeHoverStart = null;
                                            },
                                            feedback: Material(
                                              child: Card(
                                                color: color.withOpacity(0.9),
                                                child: ListTile(
                                                  title: Text(
                                                    task.title,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            child: Card(
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CreateTodoDialog(projectId: widget.projectId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
