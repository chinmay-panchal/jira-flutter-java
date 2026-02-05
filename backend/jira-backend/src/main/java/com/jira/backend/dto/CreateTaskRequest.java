package com.jira.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateTaskRequest {
    private String title;
    private String description;
    private String assignedUserUid;
    private Long projectId;
}
