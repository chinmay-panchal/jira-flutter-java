package com.jira.backend.service;

import com.jira.backend.dto.UserResponse;
import com.jira.backend.entity.User;
import com.jira.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::map)
                .collect(Collectors.toList());
    }

    public List<UserResponse> searchUsers(String query) {
        return userRepository
                .findByFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCaseOrEmailContainingIgnoreCase(
                        query, query, query
                )
                .stream()
                .map(this::map)
                .collect(Collectors.toList());
    }

    private UserResponse map(User user) {
        return UserResponse.builder()
                .uid(user.getUid())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .build();
    }
}
