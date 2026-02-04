package com.jira.backend.controller;

import com.jira.backend.dto.UserResponse;
import com.jira.backend.service.UserService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public List<UserResponse> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/search")
    public List<UserResponse> searchUsers(@RequestParam String q) {
        return userService.searchUsers(q);
    }
}
