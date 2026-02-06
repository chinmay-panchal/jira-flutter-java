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

  Future<LoginResponse> login(LoginRequest request) {
    return _dataSource.login(request);
  }

  Future<void> signup(SignupRequest request) {
    return _dataSource.signup(request);
  }

  Future<void> sendOtp(String email) {
    return _dataSource.sendOtp(email);
  }

  Future<void> verifyOtp(String email, String otp) {
    return _dataSource.verifyOtp(email, otp);
  }

  /* ---------------- PROJECT ---------------- */

  Future<List<ProjectResponse>> getMyProjects() {
    return _dataSource.getMyProjects();
  }

  Future<void> createProject(CreateProjectRequest request) {
    return _dataSource.createProject(request);
  }

  // ✅ REMOVE MEMBER (creator only)
  Future<void> removeProjectMember({
    required int projectId,
    required String memberUid,
  }) {
    return _dataSource.removeProjectMember(
      projectId: projectId,
      memberUid: memberUid,
    );
  }

  /* ---------------- TASK ---------------- */

  Future<List<TaskModel>> getTasksByProject(int projectId) {
    return _dataSource.getTasksByProject(projectId);
  }

  Future<void> createTask({
    required int projectId,
    required String title,
    required String description,
    String? assignedUserUid,
  }) {
    return _dataSource.createTask(
      projectId: projectId,
      title: title,
      description: description,
      assignedUserUid: assignedUserUid,
    );
  }

  Future<void> updateTaskStatus(int taskId, String status) {
    return _dataSource.updateTaskStatus(taskId, status);
  }

  /* ---------------- USER ---------------- */

  Future<List<UserModel>> getAllUsers() {
    return _dataSource.getAllUsers();
  }

  Future<List<UserModel>> getProjectMembers(int projectId) {
    return _dataSource.getProjectMembers(projectId);
  }
}
