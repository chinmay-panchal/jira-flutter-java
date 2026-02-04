package com.jira.backend.dto;

public record OtpResponse(
        boolean success,
        String message
) {}