package com.jira.backend.service;

import com.jira.backend.dto.CreateTaskRequest;
import com.jira.backend.dto.TaskHistoryResponse;
import com.jira.backend.dto.TaskResponse;
import com.jira.backend.dto.UpdateTaskRequest;
import com.jira.backend.dto.UpdateTaskStatusRequest;
import com.jira.backend.entity.Project;
import com.jira.backend.entity.Task;
import com.jira.backend.entity.TaskHistory;
import com.jira.backend.entity.TaskStatus;
import com.jira.backend.entity.User;
import com.jira.backend.repository.ProjectRepository;
import com.jira.backend.repository.TaskHistoryRepository;
import com.jira.backend.repository.TaskRepository;
import com.jira.backend.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import com.jira.backend.websocket.model.ProjectEvent;
import com.jira.backend.websocket.service.ProjectEventService;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final ProjectEventService projectEventService;
    private final TaskHistoryRepository taskHistoryRepository;

    public TaskService(
            TaskRepository taskRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            ProjectEventService projectEventService,
            TaskHistoryRepository taskHistoryRepository
    ) {
        this.taskRepository = taskRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.projectEventService = projectEventService;
        this.taskHistoryRepository = taskHistoryRepository;
    }

    // ─── helpers ────────────────────────────────────────────────────────────────

    private String currentUid() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private User currentUser() {
        return userRepository.findByUid(currentUid())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private void recordChange(Task task, User changedBy,
                              String fieldName, String oldVal, String newVal) {
        String oldNorm = (oldVal == null || oldVal.isBlank()) ? null : oldVal.trim();
        String newNorm = (newVal == null || newVal.isBlank()) ? null : newVal.trim();
        if (Objects.equals(oldNorm, newNorm)) return;

        TaskHistory history = TaskHistory.builder()
                .task(task)
                .changedBy(changedBy)
                .fieldName(fieldName)
                .oldValue(oldNorm)
                .newValue(newNorm)
                .build();
        taskHistoryRepository.save(history);
    }

    private static String fullName(User u) {
        if (u == null) return null;
        return (u.getFirstName() + " " + u.getLastName()).trim();
    }

    // ─── CREATE (REST) ───────────────────────────────────────────────────────────

    public TaskResponse createTask(CreateTaskRequest request) {
        User currentUser = currentUser();
        final Long currentUserId = currentUser.getId();

        Project project = projectRepository.findById(request.getProjectId())
                .orElseThrow(() -> new RuntimeException("Project not found"));

        boolean isCurrentUserMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(currentUserId));

        if (!isCurrentUserMember) {
            throw new RuntimeException("You are no longer a member of this project");
        }

        User assignedUser = null;
        if (request.getAssignedUserUid() != null) {
            assignedUser = userRepository.findByUid(request.getAssignedUserUid())
                    .orElseThrow(() -> new RuntimeException("Assigned user not found"));

            final Long assignedUserId = assignedUser.getId();
            boolean isAssignedUserMember = project.getMembers()
                    .stream()
                    .anyMatch(u -> u.getId().equals(assignedUserId));

            if (!isAssignedUserMember) {
                throw new RuntimeException("Assigned user is not a project member");
            }
        }

        Task task = Task.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .status(TaskStatus.TODO)
                .project(project)
                .assignedTo(assignedUser)
                .createdBy(currentUser)
                .storyPoints(request.getStoryPoints())
                .build();

        return mapToResponse(taskRepository.save(task));
    }

    // ─── GET (REST) ───────────────────────────────────────────────────────────────

    public List<TaskResponse> getTasksByProject(Long projectId) {
        User currentUser = currentUser();
        final Long currentUserId = currentUser.getId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new RuntimeException("Project not found"));

        boolean isMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(currentUserId));

        if (!isMember) throw new RuntimeException("You are no longer a member of this project");

        return taskRepository.findByProjectId(projectId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    // ─── GET HISTORY (REST) ───────────────────────────────────────────────────────

    public List<TaskHistoryResponse> getTaskHistory(Long taskId) {
        User currentUser = currentUser();

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        boolean isMember = task.getProject().getMembers().stream()
                .anyMatch(u -> u.getId().equals(currentUser.getId()));
        if (!isMember) throw new RuntimeException("Access denied");

        return taskHistoryRepository.findByTaskIdOrderByChangedAtDesc(taskId)
                .stream()
                .map(this::mapHistoryToResponse)
                .collect(Collectors.toList());
    }

    // ─── UPDATE STATUS (REST) ────────────────────────────────────────────────────

    @Transactional
    public TaskResponse updateTaskStatus(Long taskId, UpdateTaskStatusRequest request) {
        User currentUser = currentUser();
        final Long currentUserId = currentUser.getId();

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project project = task.getProject();

        boolean isMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(currentUserId));

        if (!isMember) throw new RuntimeException("You are no longer a member of this project");

        recordChange(task, currentUser,
                "STATUS",
                task.getStatus().name(),
                request.getStatus().name());

        task.setStatus(request.getStatus());
        return mapToResponse(taskRepository.save(task));
    }

    // ─── UPDATE TASK (REST) ───────────────────────────────────────────────────────

    @Transactional
    public TaskResponse updateTask(Long taskId, UpdateTaskRequest request) {
        User currentUser = currentUser();

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project project = task.getProject();

        boolean isProjectCreator = project.getCreator().getId().equals(currentUser.getId());
        boolean isTaskCreator = task.getCreatedBy().getId().equals(currentUser.getId());
        boolean isAssignee = task.getAssignedTo() != null &&
                task.getAssignedTo().getId().equals(currentUser.getId());

        if (!(isProjectCreator || isTaskCreator || isAssignee)) {
            throw new RuntimeException("You are not allowed to edit this task");
        }

        applyUpdatesAndRecordHistory(task, request, currentUser);

        return mapToResponse(taskRepository.save(task));
    }

    // ─── MOVE TASK (REST) ─────────────────────────────────────────────────────────

    @Transactional
    public TaskResponse moveTask(Long taskId, Long targetProjectId) {
        User currentUser = currentUser();

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project sourceProject = task.getProject();

        // Only project creator or task creator can move
        boolean isSourceProjectCreator = sourceProject.getCreator().getId().equals(currentUser.getId());
        boolean isTaskCreator = task.getCreatedBy().getId().equals(currentUser.getId());

        if (!(isSourceProjectCreator || isTaskCreator)) {
            throw new RuntimeException("You are not allowed to move this task");
        }

        Project targetProject = projectRepository.findById(targetProjectId)
                .orElseThrow(() -> new RuntimeException("Target project not found"));

        // Requester must be a member of the target project too
        boolean isMemberOfTarget = targetProject.getMembers().stream()
                .anyMatch(u -> u.getId().equals(currentUser.getId()));
        if (!isMemberOfTarget) {
            throw new RuntimeException("You are not a member of the target project");
        }

        // Record PROJECT change in history
        recordChange(task, currentUser,
                "PROJECT",
                sourceProject.getName(),
                targetProject.getName());

        // If current assignee is not a member of the target project → unassign
        User currentAssignee = task.getAssignedTo();
        if (currentAssignee != null) {
            boolean assigneeInTarget = targetProject.getMembers().stream()
                    .anyMatch(u -> u.getId().equals(currentAssignee.getId()));
            if (!assigneeInTarget) {
                recordChange(task, currentUser,
                        "ASSIGNEE", fullName(currentAssignee), null);
                task.setAssignedTo(null);
            }
        }

        task.setProject(targetProject);
        // Reset status to TODO when moving to a new project
        recordChange(task, currentUser, "STATUS", task.getStatus().name(), TaskStatus.TODO.name());
        task.setStatus(TaskStatus.TODO);

        TaskResponse response = mapToResponse(taskRepository.save(task));

        // Notify source project members: task removed
        List<String> sourceUids = sourceProject.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());
        java.util.Map<String, Object> removedPayload = new java.util.HashMap<>();
        removedPayload.put("taskId", taskId);
        removedPayload.put("projectId", sourceProject.getId());
        projectEventService.sendToMembers(sourceUids, ProjectEvent.Type.TASK_DELETED, removedPayload);

        // Notify target project members: task added
        List<String> targetUids = targetProject.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());
        projectEventService.sendToMembers(targetUids, ProjectEvent.Type.TASK_CREATED, response);

        return response;
    }

    // ─── SOCKET entry points ──────────────────────────────────────────────────────

    @Transactional
    public void createTaskForUser(CreateTaskRequest request, String uid) {
        User creator = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Project project = projectRepository.findById(request.getProjectId())
                .orElseThrow(() -> new RuntimeException("Project not found"));

        boolean isMember = project.getMembers().stream()
                .anyMatch(u -> u.getId().equals(creator.getId()));
        if (!isMember) throw new RuntimeException("Not a member");

        User assignedUser = null;
        if (request.getAssignedUserUid() != null) {
            assignedUser = userRepository.findByUid(request.getAssignedUserUid())
                    .orElseThrow(() -> new RuntimeException("Assigned user not found"));
            final Long assigneeId = assignedUser.getId();
            boolean isAssigneeMember = project.getMembers().stream()
                    .anyMatch(u -> u.getId().equals(assigneeId));
            if (!isAssigneeMember) throw new RuntimeException("Assignee not a member");
        }

        Task task = Task.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .status(TaskStatus.TODO)
                .project(project)
                .assignedTo(assignedUser)
                .createdBy(creator)
                .storyPoints(request.getStoryPoints())
                .build();

        TaskResponse response = mapToResponse(taskRepository.save(task));

        List<String> memberUids = project.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());

        projectEventService.sendToMembers(
                memberUids, ProjectEvent.Type.TASK_CREATED, response);
    }

    @Transactional
    public void updateTaskStatusForUser(Long taskId, String status, String uid) {
        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project project = task.getProject();
        boolean isMember = project.getMembers().stream()
                .anyMatch(u -> u.getId().equals(user.getId()));
        if (!isMember) throw new RuntimeException("Not a member");

        recordChange(task, user, "STATUS", task.getStatus().name(), status);

        task.setStatus(TaskStatus.valueOf(status));
        taskRepository.save(task);

        List<String> memberUids = project.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());

        java.util.Map<String, Object> payload = new java.util.HashMap<>();
        payload.put("taskId", taskId);
        payload.put("status", status);
        payload.put("projectId", project.getId());

        projectEventService.sendToMembers(
                memberUids, ProjectEvent.Type.TASK_STATUS_UPDATED, payload);
    }

    @Transactional
    public void updateTaskForUser(Long taskId, UpdateTaskRequest request, String uid) {
        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project project = task.getProject();
        boolean isProjectCreator = project.getCreator().getUid().equals(uid);
        boolean isTaskCreator = task.getCreatedBy().getUid().equals(uid);
        boolean isAssignee = task.getAssignedTo() != null &&
                task.getAssignedTo().getUid().equals(uid);

        if (!(isProjectCreator || isTaskCreator || isAssignee)) {
            throw new RuntimeException("You are not allowed to edit this task");
        }

        applyUpdatesAndRecordHistory(task, request, user);

        TaskResponse response = mapToResponse(taskRepository.save(task));

        List<String> memberUids = project.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());

        projectEventService.sendToMembers(
                memberUids, ProjectEvent.Type.TASK_UPDATED, response);
    }

    @Transactional
    public void moveTaskForUser(Long taskId, Long targetProjectId, String uid) {
        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project sourceProject = task.getProject();

        boolean isSourceProjectCreator = sourceProject.getCreator().getUid().equals(uid);
        boolean isTaskCreator = task.getCreatedBy().getUid().equals(uid);

        if (!(isSourceProjectCreator || isTaskCreator)) {
            throw new RuntimeException("You are not allowed to move this task");
        }

        Project targetProject = projectRepository.findById(targetProjectId)
                .orElseThrow(() -> new RuntimeException("Target project not found"));

        boolean isMemberOfTarget = targetProject.getMembers().stream()
                .anyMatch(u -> u.getId().equals(user.getId()));
        if (!isMemberOfTarget) {
            throw new RuntimeException("You are not a member of the target project");
        }

        recordChange(task, user, "PROJECT", sourceProject.getName(), targetProject.getName());

        User currentAssignee = task.getAssignedTo();
        if (currentAssignee != null) {
            boolean assigneeInTarget = targetProject.getMembers().stream()
                    .anyMatch(u -> u.getId().equals(currentAssignee.getId()));
            if (!assigneeInTarget) {
                recordChange(task, user, "ASSIGNEE", fullName(currentAssignee), null);
                task.setAssignedTo(null);
            }
        }

        recordChange(task, user, "STATUS", task.getStatus().name(), TaskStatus.TODO.name());
        task.setProject(targetProject);
        task.setStatus(TaskStatus.TODO);

        TaskResponse response = mapToResponse(taskRepository.save(task));

        // Notify source: task removed
        List<String> sourceUids = sourceProject.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());
        java.util.Map<String, Object> removedPayload = new java.util.HashMap<>();
        removedPayload.put("taskId", taskId);
        removedPayload.put("projectId", sourceProject.getId());
        projectEventService.sendToMembers(sourceUids, ProjectEvent.Type.TASK_DELETED, removedPayload);

        // Notify target: task added
        List<String> targetUids = targetProject.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());
        projectEventService.sendToMembers(targetUids, ProjectEvent.Type.TASK_CREATED, response);
    }

    // ─── shared mutation + history logic ─────────────────────────────────────────

    private void applyUpdatesAndRecordHistory(Task task,
                                              UpdateTaskRequest request,
                                              User changedBy) {
        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            recordChange(task, changedBy, "TITLE", task.getTitle(), request.getTitle());
            task.setTitle(request.getTitle());
        }

        if (request.getDescription() != null) {
            recordChange(task, changedBy,
                    "DESCRIPTION", task.getDescription(), request.getDescription());
            task.setDescription(request.getDescription());
        }

        if (request.isUnassign()) {
            String oldAssigneeName = fullName(task.getAssignedTo());
            recordChange(task, changedBy, "ASSIGNEE", oldAssigneeName, null);
            task.setAssignedTo(null);

        } else if (request.getAssignedUserUid() != null) {
            User newAssignee = userRepository.findByUid(request.getAssignedUserUid())
                    .orElseThrow(() -> new RuntimeException("Assigned user not found"));

            final Long assigneeId = newAssignee.getId();
            boolean isAssigneeMember = task.getProject().getMembers().stream()
                    .anyMatch(u -> u.getId().equals(assigneeId));
            if (!isAssigneeMember) throw new RuntimeException("Assigned user is not a project member");

            String oldAssigneeName = fullName(task.getAssignedTo());
            String newAssigneeName = fullName(newAssignee);
            recordChange(task, changedBy, "ASSIGNEE", oldAssigneeName, newAssigneeName);
            task.setAssignedTo(newAssignee);
        }

        if (request.getStoryPoints() != null) {
            String oldPts = task.getStoryPoints() == null
                    ? null : String.valueOf(task.getStoryPoints());
            String newPts = request.getStoryPoints() == 0.0
                    ? null : String.valueOf(request.getStoryPoints());
            recordChange(task, changedBy, "STORY_POINTS", oldPts, newPts);
            task.setStoryPoints(request.getStoryPoints() == 0.0 ? null : request.getStoryPoints());
        }
    }

    // ─── mappers ─────────────────────────────────────────────────────────────────

    private TaskResponse mapToResponse(Task task) {
        return TaskResponse.builder()
                .id(task.getId())
                .title(task.getTitle())
                .description(task.getDescription())
                .status(task.getStatus())
                .projectId(task.getProject().getId())
                .assignedUserUid(
                        task.getAssignedTo() != null
                                ? task.getAssignedTo().getUid()
                                : null
                )
                .createdByUid(task.getCreatedBy().getUid())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .storyPoints(task.getStoryPoints())
                .build();
    }

    private TaskHistoryResponse mapHistoryToResponse(TaskHistory h) {
        User by = h.getChangedBy();
        String name = fullName(by);

        return TaskHistoryResponse.builder()
                .id(h.getId())
                .changedByName(name)
                .changedByUid(by.getUid())
                .fieldName(h.getFieldName())
                .oldValue(h.getOldValue())
                .newValue(h.getNewValue())
                .changedAt(h.getChangedAt())
                .build();
    }
}