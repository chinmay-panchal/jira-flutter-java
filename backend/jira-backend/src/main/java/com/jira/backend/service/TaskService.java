package com.jira.backend.service;

import com.jira.backend.dto.CreateTaskRequest;
import com.jira.backend.dto.TaskResponse;
import com.jira.backend.dto.UpdateTaskRequest;
import com.jira.backend.dto.UpdateTaskStatusRequest;
import com.jira.backend.entity.Project;
import com.jira.backend.entity.Task;
import com.jira.backend.entity.TaskStatus;
import com.jira.backend.entity.User;
import com.jira.backend.repository.ProjectRepository;
import com.jira.backend.repository.TaskRepository;
import com.jira.backend.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import com.jira.backend.websocket.model.ProjectEvent;
import com.jira.backend.websocket.service.ProjectEventService;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;

    private final ProjectEventService projectEventService;


    public TaskService(
            TaskRepository taskRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            ProjectEventService projectEventService
    ) {
        this.taskRepository = taskRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.projectEventService = projectEventService;
    }

    // ─── helpers ────────────────────────────────────────────────────────────────

    private String currentUid() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private User currentUser() {
        return userRepository.findByUid(currentUid())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    /** Throws if the current user is NOT the project creator. */
    private void requireCreator(Project project, User user) {
        if (!project.getCreator().getId().equals(user.getId())) {
            throw new RuntimeException("Only the project creator can perform this action");
        }
    }

    // ─── existing ────────────────────────────────────────────────────────────────

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
                .build();

        return mapToResponse(taskRepository.save(task));
    }

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

        task.setStatus(request.getStatus());
        return mapToResponse(taskRepository.save(task));
    }

    // ─── new: edit task (creator only) ───────────────────────────────────────────

    /**
     * PATCH /tasks/{taskId}
     * Edit title, description and/or assignee. Only the project creator can do this.
     * To explicitly unassign, set unassign = true in the request body.
     */
    public TaskResponse updateTask(Long taskId, UpdateTaskRequest request) {
        User currentUser = currentUser();

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        Project project = task.getProject();
        requireCreator(project, currentUser);

        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            task.setTitle(request.getTitle());
        }

        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }

        if (request.isUnassign()) {
            // explicitly clear the assignee
            task.setAssignedTo(null);
        } else if (request.getAssignedUserUid() != null) {
            User newAssignee = userRepository.findByUid(request.getAssignedUserUid())
                    .orElseThrow(() -> new RuntimeException("Assigned user not found"));

            final Long assigneeId = newAssignee.getId();
            boolean isAssigneeMember = project.getMembers()
                    .stream()
                    .anyMatch(u -> u.getId().equals(assigneeId));

            if (!isAssigneeMember) {
                throw new RuntimeException("Assigned user is not a project member");
            }

            task.setAssignedTo(newAssignee);
        }

        return mapToResponse(taskRepository.save(task));
    }

    // ─── mapper ──────────────────────────────────────────────────────────────────

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
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
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
        if (!project.getCreator().getUid().equals(uid)) {
            throw new RuntimeException("Only the project creator can edit tasks");
        }

        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            task.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }
        if (request.isUnassign()) {
            task.setAssignedTo(null);
        } else if (request.getAssignedUserUid() != null) {
            User newAssignee = userRepository.findByUid(request.getAssignedUserUid())
                    .orElseThrow(() -> new RuntimeException("Assigned user not found"));
            task.setAssignedTo(newAssignee);
        }

        TaskResponse response = mapToResponse(taskRepository.save(task));

        List<String> memberUids = project.getMembers().stream()
                .map(User::getUid).collect(Collectors.toList());

        projectEventService.sendToMembers(
                memberUids, ProjectEvent.Type.TASK_UPDATED, response);
    }
}