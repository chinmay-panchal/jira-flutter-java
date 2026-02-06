package com.jira.backend.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException ex) {

        // 🔥 User removed from project
        if (ex.getMessage() != null &&
            ex.getMessage().contains("no longer a member of this project")) {

            return ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(Map.of(
                            "code", "PROJECT_ACCESS_REVOKED",
                            "message", ex.getMessage()
                    ));
        }

        // 🔥 Creator-only operations
        if (ex.getMessage() != null &&
            ex.getMessage().contains("Only creator")) {

            return ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(Map.of(
                            "code", "CREATOR_ONLY_ACTION",
                            "message", ex.getMessage()
                    ));
        }

        // 🔥 Default runtime error
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(Map.of(
                        "code", "ERROR",
                        "message", ex.getMessage() != null ? ex.getMessage() : "Something went wrong"
                ));
    }
}
