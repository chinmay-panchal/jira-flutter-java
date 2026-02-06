import 'package:flutter/material.dart';
import 'package:jira_flutter_java/Core/data/repository/app_repository.dart';
import '../ProjectModel/project_model.dart';
import '../ProjectModel/project_form_model.dart';
import '../ProjectModel/project_request.dart';

class ProjectViewModel extends ChangeNotifier {
  final AppRepository repo;

  ProjectViewModel(this.repo);

  bool isLoading = false;
  List<ProjectModel> projects = [];

  Future<void> loadProjects() async {
    isLoading = true;
    notifyListeners();

    final response = await repo.getMyProjects();

    projects = response
        .map((e) => ProjectModel(id: e.id, name: e.name, deadline: e.deadline))
        .toList();

    isLoading = false;
    notifyListeners();
  }

  Future<void> createProject(ProjectFormModel form) async {
    await repo.createProject(
      CreateProjectRequest(
        name: form.name,
        description: form.description,
        memberUids: form.members,
        deadline: form.lastDate,
      ),
    );

    await loadProjects();
  }
}
