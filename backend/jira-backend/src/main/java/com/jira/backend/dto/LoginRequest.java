package com.jira.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank String uid,
        @NotBlank String email
) {}
