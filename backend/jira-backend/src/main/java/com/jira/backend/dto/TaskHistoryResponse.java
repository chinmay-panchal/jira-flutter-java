package com.jira.backend.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskHistoryResponse {

    private Long id;

    // Human-readable name resolved on the backend — UI never shows UIDs
    private String changedByName;
    private String changedByUid;

    // e.g. "TITLE", "DESCRIPTION", "STATUS", "ASSIGNEE", "STORY_POINTS"
    private String fieldName;

    private String oldValue;   // null → "Unset" on the client
    private String newValue;   // null → "Cleared" on the client

    private LocalDateTime changedAt;
}