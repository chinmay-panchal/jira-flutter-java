import '../dataSource/data_source.dart';
import '../../../Features/Auth/AuthModel/login_request.dart';
import '../../../Features/Auth/AuthModel/login_response.dart';
import '../../../Features/Auth/AuthModel/signup_request.dart';
import '../../../Features/Project/ProjectModel/project_request.dart';
import '../../../Features/Project/ProjectModel/project_response.dart';
import '../../../Features/Dashboard/DashboardModel/task_model.dart';
import '../../../Features/User/UserModel/user_model.dart';

class AppRepository {
  final DataSource _dataSource;

  AppRepository(this._dataSource);

  /* ---------------- AUTH ---------------- */

  Future<LoginResponse> login(LoginRequest request) =>
      _dataSource.login(request);

  Future<void> signup(SignupRequest request) => _dataSource.signup(request);

  Future<void> sendOtp(String email) => _dataSource.sendOtp(email);

  Future<void> verifyOtp(String email, String otp) =>
      _dataSource.verifyOtp(email, otp);

  /* ---------------- PROJECT ---------------- */

  Future<List<ProjectResponse>> getMyProjects() => _dataSource.getMyProjects();

  Future<void> createProject(CreateProjectRequest request) =>
      _dataSource.createProject(request);

  // ✅ EDIT PROJECT (creator only)
  Future<ProjectResponse> updateProject({
    required int projectId,
    String? name,
    String? description,
    DateTime? deadline,
  }) => _dataSource.updateProject(
    projectId: projectId,
    name: name,
    description: description,
    deadline: deadline,
  );

  // ✅ ADD MEMBER (creator only)
  Future<ProjectResponse> addProjectMember({
    required int projectId,
    required String memberUid,
  }) =>
      _dataSource.addProjectMember(projectId: projectId, memberUid: memberUid);

  // ✅ REMOVE MEMBER (creator only)
  Future<void> removeProjectMember({
    required int projectId,
    required String memberUid,
  }) => _dataSource.removeProjectMember(
    projectId: projectId,
    memberUid: memberUid,
  );

  /* ---------------- TASK ---------------- */

  Future<List<TaskModel>> getTasksByProject(int projectId) =>
      _dataSource.getTasksByProject(projectId);

  Future<void> createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  }) => _dataSource.createTask(
    projectId: projectId,
    title: title,
    description: description,
    assignedUserUid: assignedUserUid,
  );

  Future<void> updateTaskStatus(int taskId, String status) =>
      _dataSource.updateTaskStatus(taskId, status);

  // ✅ EDIT TASK (creator only)
  Future<TaskModel> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? assignedUserUid,
    bool unassign = false,
  }) => _dataSource.updateTask(
    taskId: taskId,
    title: title,
    description: description,
    assignedUserUid: assignedUserUid,
    unassign: unassign,
  );

  /* ---------------- USER ---------------- */

  Future<List<UserModel>> getAllUsers() => _dataSource.getAllUsers();

  Future<List<UserModel>> getProjectMembers(int projectId) =>
      _dataSource.getProjectMembers(projectId);
}
