package com.jira.backend.service;

import com.jira.backend.dto.*;
import com.jira.backend.entity.Project;
import com.jira.backend.entity.User;
import com.jira.backend.repository.ProjectRepository;
import com.jira.backend.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;

    public ProjectService(
            ProjectRepository projectRepository,
            UserRepository userRepository
    ) {
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
    }

    // ─── helpers ────────────────────────────────────────────────────────────────

    private String currentUid() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private User currentUser() {
        return userRepository.findByUid(currentUid())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private Project requireProject(Long projectId) {
        return projectRepository.findById(projectId)
                .orElseThrow(() -> new RuntimeException("Project not found"));
    }

    /** Throws if the current user is NOT the project creator. */
    private void requireCreator(Project project, User user) {
        if (!project.getCreator().getId().equals(user.getId())) {
            throw new RuntimeException("Only the project creator can perform this action");
        }
    }

    // ─── existing ────────────────────────────────────────────────────────────────

    public ProjectResponse createProject(CreateProjectRequest request) {
        User creator = currentUser();

        List<User> members = userRepository.findByUidIn(request.getMemberUids());

        if (members.stream().noneMatch(u -> u.getUid().equals(creator.getUid()))) {
            members.add(creator);
        }

        Project project = Project.builder()
                .name(request.getName())
                .description(request.getDescription())
                .deadline(request.getDeadline())
                .creator(creator)
                .members(members)
                .build();

        return map(projectRepository.save(project));
    }

    public List<ProjectResponse> getMyProjects() {
        User user = currentUser();
        return projectRepository.findByMembers_Id(user.getId())
                .stream()
                .map(this::map)
                .collect(Collectors.toList());
    }

    public List<User> getProjectMembers(Long projectId) {
        User requester = currentUser();
        Project project = requireProject(projectId);

        boolean isMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(requester.getId()));

        if (!isMember) throw new RuntimeException("Access denied");

        return project.getMembers();
    }

    // ✅ REMOVE MEMBER (creator only)
    public void removeMember(Long projectId, String memberUid, String currentUserUid) {
        Project project = requireProject(projectId);
        User currentUser = userRepository.findByUid(currentUserUid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        requireCreator(project, currentUser);

        if (project.getCreator().getUid().equals(memberUid)) {
            throw new RuntimeException("Creator cannot be removed");
        }

        boolean removed = project.getMembers().removeIf(u -> u.getUid().equals(memberUid));
        if (!removed) throw new RuntimeException("User is not a member of this project");

        projectRepository.save(project);
    }

    // ─── new edit endpoints (creator only) ───────────────────────────────────────

    /**
     * PATCH /projects/{projectId}
     * Edit name, description and/or deadline. Only non-null fields are updated.
     */
    public ProjectResponse updateProject(Long projectId, UpdateProjectRequest request) {
        User user = currentUser();
        Project project = requireProject(projectId);
        requireCreator(project, user);

        if (request.getName() != null && !request.getName().isBlank()) {
            project.setName(request.getName());
        }
        if (request.getDescription() != null) {
            project.setDescription(request.getDescription());
        }
        if (request.getDeadline() != null) {
            project.setDeadline(request.getDeadline());
        }

        return map(projectRepository.save(project));
    }

    /**
     * POST /projects/{projectId}/members
     * Add a member by UID. Only the creator can do this.
     */
    public ProjectResponse addMember(Long projectId, AddProjectMemberRequest request) {
        User user = currentUser();
        Project project = requireProject(projectId);
        requireCreator(project, user);

        User newMember = userRepository.findByUid(request.getMemberUid())
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean alreadyMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(newMember.getId()));

        if (alreadyMember) throw new RuntimeException("User is already a member of this project");

        project.getMembers().add(newMember);
        return map(projectRepository.save(project));
    }

    // ─── mapper ──────────────────────────────────────────────────────────────────

    private ProjectResponse map(Project project) {
        return ProjectResponse.builder()
                .id(project.getId())
                .name(project.getName())
                .description(project.getDescription())
                .deadline(project.getDeadline())
                .creatorUid(project.getCreator().getUid())
                .memberUids(
                        project.getMembers()
                                .stream()
                                .map(User::getUid)
                                .collect(Collectors.toList())
                )
                .createdAt(project.getCreatedAt())
                .build();
    }
}