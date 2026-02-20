package com.jira.backend.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class UpdateProjectRequest {
    private Long projectId; // needed for socket routing
    private String name;
    private String description;
    private LocalDateTime deadline;
}