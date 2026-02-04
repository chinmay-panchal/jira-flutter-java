package com.jira.backend.dto;

import com.jira.backend.entity.TaskStatus;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateTaskRequest {
    private String title;
    private String description;
    private TaskStatus status;
    private String assignedUserUid;
    private Long projectId;
}
