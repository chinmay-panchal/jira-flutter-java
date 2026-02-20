package com.jira.backend.dto;

import lombok.Data;

@Data
public class AddProjectMemberRequest {
    private Long projectId; // needed for socket routing
    private String memberUid;
}