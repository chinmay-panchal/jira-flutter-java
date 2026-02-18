package com.jira.backend.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class UpdateProjectRequest {
    private String name;
    private String description;
    private LocalDateTime deadline;
}