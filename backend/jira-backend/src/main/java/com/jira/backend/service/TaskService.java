package com.jira.backend.service;

import com.jira.backend.dto.CreateTaskRequest;
import com.jira.backend.dto.TaskResponse;
import com.jira.backend.entity.Project;
import com.jira.backend.entity.Task;
import com.jira.backend.entity.TaskStatus;
import com.jira.backend.entity.User;
import com.jira.backend.repository.ProjectRepository;
import com.jira.backend.repository.TaskRepository;
import com.jira.backend.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;

    public TaskService(
            TaskRepository taskRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository
    ) {
        this.taskRepository = taskRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
    }

    public TaskResponse createTask(CreateTaskRequest request) {
        String uid = SecurityContextHolder.getContext().getAuthentication().getName();

        Project project = projectRepository.findById(request.getProjectId())
                .orElseThrow(() -> new RuntimeException("Project not found"));

        User creator = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        User assignedUser = null;
        if (request.getAssignedUserUid() != null) {
            assignedUser = userRepository.findByUid(request.getAssignedUserUid())
                    .orElseThrow(() -> new RuntimeException("Assigned user not found"));
        }

        Task task = Task.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .status(request.getStatus() != null ? request.getStatus() : TaskStatus.TODO)
                .project(project)
                .assignedTo(assignedUser)
                .build();

        Task saved = taskRepository.save(task);
        return mapToResponse(saved);
    }

    public List<TaskResponse> getTasksByProject(Long projectId) {
        return taskRepository.findByProjectId(projectId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private TaskResponse mapToResponse(Task task) {
        return TaskResponse.builder()
                .id(task.getId())
                .title(task.getTitle())
                .description(task.getDescription())
                .status(task.getStatus())
                .projectId(task.getProject().getId())
                .assignedUserUid(
                        task.getAssignedTo() != null ? task.getAssignedTo().getUid() : null
                )
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }
}
