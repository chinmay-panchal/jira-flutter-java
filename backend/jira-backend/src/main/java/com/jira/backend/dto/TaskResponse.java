package com.jira.backend.dto;

import com.jira.backend.entity.TaskStatus;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class TaskResponse {
    private Long id;
    private String title;
    private String description;
    private TaskStatus status;
    private Long projectId;
    private String assignedUserUid;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
