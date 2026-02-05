package com.jira.backend.service;

import com.jira.backend.dto.CreateProjectRequest;
import com.jira.backend.dto.ProjectResponse;
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

    public ProjectResponse createProject(CreateProjectRequest request) {
        String creatorUid = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        User creator = userRepository.findByUid(creatorUid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<User> members = userRepository.findByUidIn(request.getMemberUids());

        if (members.stream().noneMatch(u -> u.getUid().equals(creatorUid))) {
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
        String uid = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        User user = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return projectRepository.findByMembers_Id(user.getId())
                .stream()
                .map(this::map)
                .collect(Collectors.toList());
    }

    public List<User> getProjectMembers(Long projectId) {
        String uid = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        User requester = userRepository.findByUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new RuntimeException("Project not found"));

        boolean isMember = project.getMembers()
                .stream()
                .anyMatch(u -> u.getId().equals(requester.getId()));

        if (!isMember) {
            throw new RuntimeException("Access denied");
        }

        return project.getMembers();
    }

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
