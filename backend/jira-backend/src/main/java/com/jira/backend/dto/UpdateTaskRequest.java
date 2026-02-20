package com.jira.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateTaskRequest {
    private Long taskId;     // add this
    private String status;   // add this
    private String title;
    private String description;
    private String assignedUserUid;
    private boolean unassign;
}