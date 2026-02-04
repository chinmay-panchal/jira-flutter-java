package com.jira.backend.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserResponse {
    private String uid;
    private String firstName;
    private String lastName;
    private String email;
}
