package com.jira.backend.controller;

import com.jira.backend.dto.CreateTaskRequest;
import com.jira.backend.dto.TaskHistoryResponse;
import com.jira.backend.dto.TaskResponse;
import com.jira.backend.dto.UpdateTaskRequest;
import com.jira.backend.dto.UpdateTaskStatusRequest;
import com.jira.backend.service.TaskService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/tasks")
@CrossOrigin
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @PostMapping
    public TaskResponse createTask(@RequestBody CreateTaskRequest request) {
        return taskService.createTask(request);
    }

    @GetMapping("/project/{projectId}")
    public List<TaskResponse> getTasksByProject(@PathVariable Long projectId) {
        return taskService.getTasksByProject(projectId);
    }

    @PatchMapping("/{taskId}/status")
    public TaskResponse updateTaskStatus(
            @PathVariable Long taskId,
            @RequestBody UpdateTaskStatusRequest request
    ) {
        return taskService.updateTaskStatus(taskId, request);
    }

    @PatchMapping("/{taskId}")
    public TaskResponse updateTask(
            @PathVariable Long taskId,
            @RequestBody UpdateTaskRequest request
    ) {
        return taskService.updateTask(taskId, request);
    }

    @PatchMapping("/{taskId}/move")
    public TaskResponse moveTask(
            @PathVariable Long taskId,
            @RequestBody Map<String, Long> body
    ) {
        Long targetProjectId = body.get("targetProjectId");
        if (targetProjectId == null) {
            throw new RuntimeException("targetProjectId is required");
        }
        return taskService.moveTask(taskId, targetProjectId);
    }

    @GetMapping("/{taskId}/history")
    public List<TaskHistoryResponse> getTaskHistory(@PathVariable Long taskId) {
        return taskService.getTaskHistory(taskId);
    }
}