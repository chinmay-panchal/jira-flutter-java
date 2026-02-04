package com.jira.backend.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class CreateProjectRequest {
    private String name;
    private String description;
    private LocalDateTime deadline;
    private List<String> memberUids;
}
