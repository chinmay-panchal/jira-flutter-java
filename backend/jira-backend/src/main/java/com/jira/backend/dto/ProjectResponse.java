package com.jira.backend.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class ProjectResponse {
    private Long id;
    private String name;
    private String description;
    private LocalDateTime deadline;
    private String creatorUid;
    private List<String> memberUids;
    private LocalDateTime createdAt;
}
