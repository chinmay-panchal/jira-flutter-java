package com.jira.backend.service;

import com.jira.backend.dto.OtpResponse;
import com.jira.backend.entity.OtpToken;
import com.jira.backend.repository.OtpTokenRepository;
import com.jira.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Random;

@Service
public class OtpService {

    private final OtpTokenRepository otpTokenRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public OtpService(
            OtpTokenRepository otpTokenRepository,
            UserRepository userRepository,
            EmailService emailService
    ) {
        this.otpTokenRepository = otpTokenRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    public OtpResponse sendOtp(String email) {
        // Check if user exists
        boolean userExists = userRepository.findByEmail(email).isPresent();
        if (!userExists) {
            return new OtpResponse(false, "Email not registered");
        }

        String otp = generateOtp();

        OtpToken token = new OtpToken();
        token.setEmail(email);
        token.setOtp(otp);
        token.setVerified(false);
        token.setExpiresAt(LocalDateTime.now().plusMinutes(5));
        otpTokenRepository.save(token);

        // Send email
        try {
            emailService.sendOtpEmail(email, otp);
            return new OtpResponse(true, "OTP sent to email");
        } catch (Exception e) {
            return new OtpResponse(false, "Failed to send OTP email: " + e.getMessage());
        }
    }

    public OtpResponse verifyOtp(String email, String otp) {
        return otpTokenRepository.findTopByEmailOrderByExpiresAtDesc(email)
                .filter(t -> !t.isVerified())
                .filter(t -> t.getExpiresAt().isAfter(LocalDateTime.now()))
                .filter(t -> t.getOtp().equals(otp))
                .map(t -> {
                    t.setVerified(true);
                    otpTokenRepository.save(t);
                    return new OtpResponse(true, "OTP verified successfully");
                })
                .orElse(new OtpResponse(false, "Invalid or expired OTP"));
    }

    private String generateOtp() {
        return String.valueOf(100000 + new Random().nextInt(900000));
    }
}