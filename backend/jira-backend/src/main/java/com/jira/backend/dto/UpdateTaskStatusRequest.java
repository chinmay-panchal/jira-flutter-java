package com.jira.backend.dto;

import com.jira.backend.entity.TaskStatus;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateTaskStatusRequest {
    private TaskStatus status;
}
