import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ProjectViewModel/project_view_model.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
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
                    return ListTile(
                      title: Text(project.name),
                      trailing: Text(
                        '${project.deadline.day}/${project.deadline.month}/${project.deadline.year}',
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
