package com.jira.backend.dto;

import com.jira.backend.entity.User;

public record LoginResponse(
        String token,
        User user
) {}
