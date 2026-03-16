package com.jira.backend.websocket;

import com.jira.backend.dto.*;
import com.jira.backend.service.ProjectService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import com.jira.backend.service.TaskService;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@Slf4j
public class ProjectMessageController {

    private final ProjectService projectService;
    private final TaskService taskService;

    @MessageMapping("/projects.create")
    public void createProject(@Payload CreateProjectRequest request, Principal principal) {
        projectService.createProjectForUser(request, principal.getName());
    }

    @MessageMapping("/projects.update")
    public void updateProject(@Payload UpdateProjectRequest request, Principal principal) {
        projectService.updateProjectForUser(request.getProjectId(), request, principal.getName());
    }

    @MessageMapping("/projects.addMember")
    public void addMember(@Payload AddProjectMemberRequest request, Principal principal) {
        projectService.addMemberForUser(request.getProjectId(), request, principal.getName());
    }

    @MessageMapping("/projects.removeMember")
    public void removeMember(@Payload RemoveMemberRequest request, Principal principal) {
        projectService.removeMember(request.getProjectId(), request.getMemberUid(), principal.getName());
    }

    @MessageMapping("/tasks.create")
    public void createTask(@Payload CreateTaskRequest request, Principal principal) {
        taskService.createTaskForUser(request, principal.getName());
    }

    @MessageMapping("/tasks.updateStatus")
    public void updateTaskStatus(@Payload UpdateTaskRequest request, Principal principal) {
        taskService.updateTaskStatusForUser(
                request.getTaskId(), request.getStatus(), principal.getName());
    }

    @MessageMapping("/tasks.update")
    public void updateTask(@Payload UpdateTaskRequest request, Principal principal) {
        taskService.updateTaskForUser(request.getTaskId(), request, principal.getName());
    }

    @MessageMapping("/tasks.move")
    public void moveTask(@Payload Map<String, Object> payload, Principal principal) {
        Long taskId = ((Number) payload.get("taskId")).longValue();
        Long targetProjectId = ((Number) payload.get("targetProjectId")).longValue();
        taskService.moveTaskForUser(taskId, targetProjectId, principal.getName());
    }
}