import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardViewModel/task_view_model.dart';
import 'package:jira_flutter_java/Core/theme/theme_settings_screen.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/frequent_project_service.dart';
import 'package:provider/provider.dart';

import 'package:jira_flutter_java/Core/theme/theme_provider.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import '../ProjectViewModel/project_view_model.dart';
import '../../Dashboard/DashboardView/dashboard_screen.dart';
import 'create_project_dialog.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final FrequentProjectsService _frequentService = FrequentProjectsService();
  Set<int> _frequentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProjectViewModel>().init();
      await _refreshFrequentIds();
    });
  }

  Future<void> _refreshFrequentIds() async {
    final viewModel = context.read<ProjectViewModel>();
    final allIds = viewModel.projects.map((p) => p.id).toList();
    final ids = await _frequentService.getFrequentProjectIds(allIds);
    if (mounted) setState(() => _frequentIds = ids);
  }

  Future<void> _openProject(int projectId) async {
    final viewModel = context.read<ProjectViewModel>();
    await _frequentService.recordView(projectId);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => TaskViewModel(ctx.read<AppRepository>()),
          child: DashboardScreen(projectId: projectId),
        ),
      ),
    );
    if (mounted) {
      await viewModel.loadProjects();
      await _refreshFrequentIds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjectViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final recentProjects = viewModel.projects
        .where((p) => _frequentIds.contains(p.id))
        .toList();
    final allProjects = viewModel.projects;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      // ── Drawer — identical structure to DashboardScreen ──────────────
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
              builder: (context, themeProvider, _) => ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Dark Mode'),
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

      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.projects.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<ProjectViewModel>().loadProjects();
                await _refreshFrequentIds();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                children: [
                  // ── Recent ──────────────────────────────────────
                  if (recentProjects.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'Recent',
                      icon: Icons.history_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    ...recentProjects.map(
                      (p) => _ProjectCard(
                        project: p,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () => _openProject(p.id),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── All Projects ────────────────────────────────
                  _SectionHeader(
                    label: 'All Projects',
                    icon: Icons.folder_outlined,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  ...allProjects.map(
                    (p) => _ProjectCard(
                      project: p,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      onTap: () => _openProject(p.id),
                    ),
                  ),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const CreateProjectDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ProjectViewModel>().loadProjects();
        await _refreshFrequentIds();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 56,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No projects yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + to create one',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Project Card ───────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final dynamic project;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project #${project.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow — same style as task card ticket chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
