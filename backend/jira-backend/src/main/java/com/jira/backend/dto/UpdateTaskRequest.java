package com.jira.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateTaskRequest {
    private String title;
    private String description;
    private String assignedUserUid; // null = unassign
    private boolean unassign; // explicit flag to set assignedTo = null
}