package com.jira.backend.repository;

import com.jira.backend.entity.PasswordOtp;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PasswordOtpRepository extends JpaRepository<PasswordOtp, Long> {

    Optional<PasswordOtp> findTopByEmailOrderByIdDesc(String email);
}
