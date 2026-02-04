package com.jira.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record SignupRequest(
        @NotBlank String uid,
        @NotBlank String email,
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotBlank String mobile
) {}
