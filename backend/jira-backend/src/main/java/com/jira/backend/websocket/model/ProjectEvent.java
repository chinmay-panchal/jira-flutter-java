package com.jira.backend.websocket.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProjectEvent {

    public enum Type {
        // Project events
        PROJECT_CREATED,
        PROJECT_UPDATED,
        MEMBER_ADDED,
        MEMBER_REMOVED,

        // Task events (ready for future use)
        TASK_CREATED,
        TASK_UPDATED,
        TASK_STATUS_UPDATED,
        TASK_DELETED
    }

    private Type type;

    /**
     * Dynamic payload — each event type sends only what's needed.
     *
     * PROJECT_CREATED   → full ProjectResponse
     * PROJECT_UPDATED   → { projectId, name?, description?, deadline? }
     * MEMBER_ADDED      → { projectId, memberUid }
     * MEMBER_REMOVED    → { projectId, memberUid }
     * TASK_CREATED      → full TaskResponse
     * TASK_STATUS_UPDATED → { taskId, status }
     * TASK_UPDATED      → { taskId, title?, description?, assignedUserUid? }
     * TASK_DELETED      → { taskId }
     */
    private Object payload;

    private long timestamp;
}