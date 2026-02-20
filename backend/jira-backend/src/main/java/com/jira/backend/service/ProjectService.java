package com.jira.backend.service;

import com.jira.backend.dto.*;
import com.jira.backend.entity.Project;
import com.jira.backend.entity.User;
import com.jira.backend.repository.ProjectRepository;
import com.jira.backend.repository.UserRepository;
import com.jira.backend.websocket.model.ProjectEvent;
import com.jira.backend.websocket.service.ProjectEventService;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final ProjectEventService projectEventService;

    public ProjectService(
            ProjectRepository projectRepository,
            UserRepository userRepository,
            ProjectEventService projectEventService
    ) {
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.projectEventService = projectEventService;
    }

    // ─── WebSocket entry points (uid passed explicitly) ──────────────────────────

    public ProjectResponse createProjectForUser(CreateProjectRequest request, String uid) {
        User creator = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

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

        ProjectResponse response = map(projectRepository.save(project));

        projectEventService.sendToMembers(
                response.getMemberUids(),
                ProjectEvent.Type.PROJECT_CREATED,
                response
        );

        return response;
    }

    @Transactional
    public ProjectResponse updateProjectForUser(Long projectId, UpdateProjectRequest request, String uid) {
        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Project project = requireProject(projectId);
        requireCreator(project, user);

        Map<String, Object> delta = new HashMap<>();
        delta.put("projectId", projectId);

        if (request.getName() != null && !request.getName().isBlank()) {
            project.setName(request.getName());
            delta.put("name", request.getName());
        }
        if (request.getDescription() != null) {
            project.setDescription(request.getDescription());
            delta.put("description", request.getDescription());
        }
        if (request.getDeadline() != null) {
            project.setDeadline(request.getDeadline());
            delta.put("deadline", request.getDeadline());
        }

        projectRepository.save(project);

        projectEventService.sendToMembers(
                memberUids(project),
                ProjectEvent.Type.PROJECT_UPDATED,
                delta
        );

        return map(project);
    }

    @Transactional
    public ProjectResponse addMemberForUser(Long projectId, AddProjectMemberRequest request, String uid) {
        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Project project = requireProject(projectId);
        requireCreator(project, user);

        User newMember = userRepository.findByUid(request.getMemberUid())
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean alreadyMember = project.getMembers().stream()
                .anyMatch(u -> u.getId().equals(newMember.getId()));
        if (alreadyMember) throw new RuntimeException("User is already a member");

        project.getMembers().add(newMember);
        ProjectResponse response = map(projectRepository.save(project));

        Map<String, Object> payload = new HashMap<>();
        payload.put("projectId", projectId);
        payload.put("memberUid", request.getMemberUid());
        payload.put("project", response);

        projectEventService.sendToMembers(
                response.getMemberUids(),
                ProjectEvent.Type.MEMBER_ADDED,
                payload
        );

        return response;
    }

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

    private void requireCreator(Project project, User user) {
        if (!project.getCreator().getId().equals(user.getId())) {
            throw new RuntimeException("Only the project creator can perform this action");
        }
    }

    private List<String> memberUids(Project project) {
        return project.getMembers().stream()
                .map(User::getUid)
                .collect(Collectors.toList());
    }

    // ─── CREATE ──────────────────────────────────────────────────────────────────

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

        ProjectResponse response = map(projectRepository.save(project));

        // Broadcast full project to all members
        projectEventService.sendToMembers(
                response.getMemberUids(),
                ProjectEvent.Type.PROJECT_CREATED,
                response  // full payload
        );

        return response;
    }

    // ─── GET ─────────────────────────────────────────────────────────────────────

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

    // ─── UPDATE ──────────────────────────────────────────────────────────────────

    public ProjectResponse updateProject(Long projectId, UpdateProjectRequest request) {
        User user = currentUser();
        Project project = requireProject(projectId);
        requireCreator(project, user);

        // Build minimal delta payload — only what actually changed
        Map<String, Object> delta = new HashMap<>();
        delta.put("projectId", projectId);

        if (request.getName() != null && !request.getName().isBlank()) {
            project.setName(request.getName());
            delta.put("name", request.getName());
        }
        if (request.getDescription() != null) {
            project.setDescription(request.getDescription());
            delta.put("description", request.getDescription());
        }
        if (request.getDeadline() != null) {
            project.setDeadline(request.getDeadline());
            delta.put("deadline", request.getDeadline());
        }

        projectRepository.save(project);

        // Send only the delta — not the full object
        projectEventService.sendToMembers(
                memberUids(project),
                ProjectEvent.Type.PROJECT_UPDATED,
                delta
        );

        return map(project);
    }

    // ─── ADD MEMBER ──────────────────────────────────────────────────────────────

    public ProjectResponse addMember(Long projectId, AddProjectMemberRequest request) {
        User user = currentUser();
        Project project = requireProject(projectId);
        requireCreator(project, user);

        User newMember = userRepository.findByUid(request.getMemberUid())
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean alreadyMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(newMember.getId()));

        if (alreadyMember) throw new RuntimeException("User is already a member");

        project.getMembers().add(newMember);
        ProjectResponse response = map(projectRepository.save(project));

        // Notify ALL members (including new one) about the addition
        // The new member gets full project so their list populates immediately
        Map<String, Object> payload = new HashMap<>();
        payload.put("projectId", projectId);
        payload.put("memberUid", request.getMemberUid());
        payload.put("project", response); // full project for the new member

        projectEventService.sendToMembers(
                response.getMemberUids(),
                ProjectEvent.Type.MEMBER_ADDED,
                payload
        );

        return response;
    }

    // ─── REMOVE MEMBER ───────────────────────────────────────────────────────────

    @Transactional
    public void removeMember(Long projectId, String memberUid, String currentUserUid) {
        Project project = requireProject(projectId);
        User currentUser = userRepository.findByUid(currentUserUid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        requireCreator(project, currentUser);

        if (project.getCreator().getUid().equals(memberUid)) {
            throw new RuntimeException("Creator cannot be removed");
        }

        List<String> allMemberUids = memberUids(project); // needs session → fixed by @Transactional

        boolean removed = project.getMembers().removeIf(u -> u.getUid().equals(memberUid));
        if (!removed) throw new RuntimeException("User is not a member");

        projectRepository.save(project);

        Map<String, Object> payload = new HashMap<>();
        payload.put("projectId", projectId);
        payload.put("memberUid", memberUid);

        projectEventService.sendToMembers(
                allMemberUids,
                ProjectEvent.Type.MEMBER_REMOVED,
                payload
        );
    }
    // ─── MAPPER ──────────────────────────────────────────────────────────────────

    private ProjectResponse map(Project project) {
        return ProjectResponse.builder()
                .id(project.getId())
                .name(project.getName())
                .description(project.getDescription())
                .deadline(project.getDeadline())
                .creatorUid(project.getCreator().getUid())
                .memberUids(memberUids(project))
                .createdAt(project.getCreatedAt())
                .build();
    }
}