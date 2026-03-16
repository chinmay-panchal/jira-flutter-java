package com.jira.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "task_history", indexes = {
        @Index(name = "idx_task_history_task_id", columnList = "task_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── which task this history entry belongs to ──────────────────────────────
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    // ── who made the change ───────────────────────────────────────────────────
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "changed_by_user_id", nullable = false)
    private User changedBy;

    // ── what changed ──────────────────────────────────────────────────────────
    // e.g. "TITLE", "DESCRIPTION", "STATUS", "ASSIGNEE", "STORY_POINTS"
    @Column(nullable = false, length = 50)
    private String fieldName;

    @Column(length = 5000)
    private String oldValue;   // null means "was empty / unset"

    @Column(length = 5000)
    private String newValue;   // null means "cleared"

    // ── when ─────────────────────────────────────────────────────────────────
    @Column(nullable = false, updatable = false)
    private LocalDateTime changedAt;

    @PrePersist
    public void prePersist() {
        this.changedAt = LocalDateTime.now();
    }
}