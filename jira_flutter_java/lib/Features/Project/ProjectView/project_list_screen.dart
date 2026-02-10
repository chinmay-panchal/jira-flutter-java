import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardViewModel/task_view_model.dart';
import 'package:jira_flutter_java/Core/theme/theme_settings_screen.dart';
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectViewModel>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjectViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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

            /// 🎨 Theme Settings
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),

            /// 🌗 Quick Dark Mode Toggle
            Consumer<ThemeProvider>(
              builder: (_, themeProvider, __) => ListTile(
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

            /// 🚪 Logout
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
          ? const Center(
              child: Text(
                'No projects yet.\nTap + to create one',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: viewModel.projects.length,
              itemBuilder: (context, index) {
                final project = viewModel.projects[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    // subtitle: Text(
                    //   'Deadline: ${project.deadline.day}/${project.deadline.month}/${project.deadline.year}',
                    // ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (ctx) =>
                                TaskViewModel(ctx.read<AppRepository>()),
                            child: DashboardScreen(projectId: project.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const CreateProjectDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
