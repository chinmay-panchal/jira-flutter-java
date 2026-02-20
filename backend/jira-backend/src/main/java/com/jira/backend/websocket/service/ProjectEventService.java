package com.jira.backend.websocket.service;

import com.jira.backend.websocket.model.ProjectEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProjectEventService {

private final SimpMessagingTemplate messagingTemplate;

/**
 * Send an event to every affected member.
 * Each user receives it on /user/queue/projects (user-specific, private).
 *
 * @param memberUids list of user UIDs who should receive this event
 * @param type       the event type
 * @param payload    dynamic payload — send only what's needed for this event type
 */
public void sendToMembers(List<String> memberUids, ProjectEvent.Type type, Object payload) {
    ProjectEvent event = ProjectEvent.builder()
            .type(type)
            .payload(payload)
            .timestamp(System.currentTimeMillis())
            .build();

    for (String uid : memberUids) {
        try {
            messagingTemplate.convertAndSendToUser(uid, "/queue/projects", event);
            log.debug("Sent {} event to uid: {}", type, uid);
        } catch (Exception e) {
            log.error("Failed to send {} event to uid: {}", type, uid, e);
        }
    }
}
}