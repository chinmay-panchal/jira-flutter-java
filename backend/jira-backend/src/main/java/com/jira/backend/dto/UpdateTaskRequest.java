package com.jira.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateTaskRequest {
    private Long taskId;
    private String status;
    private String title;
    private String description;
    private String assignedUserUid;
    private boolean unassign;
    private Double storyPoints;
    private Long targetProjectId; // null = no move
}