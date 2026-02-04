package com.jira.backend.controller;

import com.jira.backend.dto.OtpResponse;
import com.jira.backend.dto.SendOtpRequest;
import com.jira.backend.dto.VerifyOtpRequest;
import com.jira.backend.service.OtpService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth/otp")
public class OtpController {

    private final OtpService otpService;

    public OtpController(OtpService otpService) {
        this.otpService = otpService;
    }

    @PostMapping("/send")
    public ResponseEntity<OtpResponse> send(@Valid @RequestBody SendOtpRequest request) {
        OtpResponse response = otpService.sendOtp(request.email());

        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }

        return ResponseEntity.ok(response);
    }

    @PostMapping("/verify")
    public ResponseEntity<OtpResponse> verify(@Valid @RequestBody VerifyOtpRequest request) {
        OtpResponse response = otpService.verifyOtp(request.email(), request.otp());

        if (!response.success()) {
            return ResponseEntity.badRequest().body(response);
        }

        return ResponseEntity.ok(response);
    }
}