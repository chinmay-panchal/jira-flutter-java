package com.jira.backend.controller;

import com.jira.backend.dto.*;
import com.jira.backend.entity.User;
import com.jira.backend.service.ProjectService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/projects")
@CrossOrigin
public class ProjectController {

    private final ProjectService projectService;

    public ProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @PostMapping
    public ProjectResponse createProject(@RequestBody CreateProjectRequest request) {
        return projectService.createProject(request);
    }

    @GetMapping
    public List<ProjectResponse> getMyProjects() {
        return projectService.getMyProjects();
    }

    @GetMapping("/{projectId}/members")
    public List<User> getProjectMembers(@PathVariable Long projectId) {
        return projectService.getProjectMembers(projectId);
    }

    // ✅ EDIT PROJECT (creator only) — name, description, deadline
    @PatchMapping("/{projectId}")
    public ProjectResponse updateProject(
            @PathVariable Long projectId,
            @RequestBody UpdateProjectRequest request
    ) {
        return projectService.updateProject(projectId, request);
    }

    // ✅ ADD MEMBER (creator only)
    @PostMapping("/{projectId}/members")
    public ProjectResponse addMember(
            @PathVariable Long projectId,
            @RequestBody AddProjectMemberRequest request
    ) {
        return projectService.addMember(projectId, request);
    }

    // ✅ REMOVE MEMBER (creator only)
    @DeleteMapping("/{projectId}/members/{memberUid}")
    public void removeMember(
            @PathVariable Long projectId,
            @PathVariable String memberUid,
            Authentication authentication
    ) {
        String currentUserUid = authentication.getName();
        projectService.removeMember(projectId, memberUid, currentUserUid);
    }
}