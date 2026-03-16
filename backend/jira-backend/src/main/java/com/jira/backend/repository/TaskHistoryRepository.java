package com.jira.backend.repository;

import com.jira.backend.entity.TaskHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TaskHistoryRepository extends JpaRepository<TaskHistory, Long> {

    // Returns all history for a task ordered newest-first
    List<TaskHistory> findByTaskIdOrderByChangedAtDesc(Long taskId);
}