import 'package:jira_flutter_java/Features/Auth/AuthModel/login_request.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/login_response.dart';
import 'package:jira_flutter_java/Features/Auth/AuthModel/signup_request.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_history_model.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_request.dart';
import 'package:jira_flutter_java/Features/Project/ProjectModel/project_response.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardModel/task_model.dart';
import 'package:jira_flutter_java/Features/User/UserModel/user_model.dart';

abstract class DataSource {
  /* -------- AUTH -------- */
  Future<LoginResponse> login(LoginRequest request);
  Future<void> signup(SignupRequest request);
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String otp);

  /* -------- PROJECT -------- */
  Future<List<ProjectResponse>> getMyProjects();
  Future<void> createProject(CreateProjectRequest request);
  Future<ProjectResponse> updateProject({
    required int projectId,
    String? name,
    String? description,
    DateTime? deadline,
  });
  Future<ProjectResponse> addProjectMember({
    required int projectId,
    required String memberUid,
  });
  Future<void> removeProjectMember({
    required int projectId,
    required String memberUid,
  });

  /* -------- TASK -------- */
  Future<List<TaskModel>> getTasksByProject(int projectId);
  Future<List<TaskHistoryModel>> getTaskHistory(int taskId);

  Future<void> createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  });
  Future<void> updateTaskStatus(int taskId, String status);
  Future<TaskModel> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? assignedUserUid,
    bool unassign = false,
  });

  /* -------- USER -------- */
  Future<List<UserModel>> getAllUsers();
  Future<List<UserModel>> getProjectMembers(int projectId);
}
