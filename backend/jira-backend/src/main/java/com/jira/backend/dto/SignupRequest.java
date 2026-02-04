package com.jira.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

public record SignupRequest(
        @NotBlank String uid,
        @NotBlank String email,
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotBlank String mobile
) {
    @Getter
    @Setter
    public static class CreateProjectRequest {
        private String name;
        private String description;
        private LocalDateTime deadline;
        private List<String> memberUids;
    }
}
