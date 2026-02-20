package com.jira.backend.controller;

import com.jira.backend.dto.ProjectResponse;
import com.jira.backend.entity.User;
import com.jira.backend.service.ProjectService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/projects")
@CrossOrigin
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectService projectService;

    @GetMapping
    public List<ProjectResponse> getMyProjects() {
        return projectService.getMyProjects();
    }

    @GetMapping("/{projectId}/members")
    public List<User> getProjectMembers(@PathVariable Long projectId) {
        return projectService.getProjectMembers(projectId);
    }
}