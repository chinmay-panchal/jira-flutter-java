package com.jira.backend.dto;

import lombok.Data;

@Data
public class RemoveMemberRequest {
    private Long projectId;
    private String memberUid;
}