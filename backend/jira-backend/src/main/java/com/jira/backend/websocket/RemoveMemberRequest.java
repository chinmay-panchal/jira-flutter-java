package com.jira.backend.websocket;

import lombok.Data;

@Data
public class RemoveMemberRequest {
    private Long projectId;
    private String memberUid;
}