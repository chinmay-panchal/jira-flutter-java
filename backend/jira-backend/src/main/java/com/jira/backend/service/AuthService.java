package com.jira.backend.service;

import com.jira.backend.config.JwtUtil;
import com.jira.backend.dto.LoginRequest;
import com.jira.backend.dto.LoginResponse;
import com.jira.backend.dto.SignupRequest;
import com.jira.backend.entity.User;
import com.jira.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepository, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
    }

    public void signup(SignupRequest request) {
        userRepository.findByUid(request.uid())
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .uid(request.uid())
                                .email(request.email())
                                .firstName(request.firstName())
                                .lastName(request.lastName())
                                .mobile(request.mobile())
                                .build()
                ));
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUid(request.uid())
                .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));

        String token = jwtUtil.generateToken(user.getUid(), user.getEmail());
        return new LoginResponse(token, user);
    }
}
