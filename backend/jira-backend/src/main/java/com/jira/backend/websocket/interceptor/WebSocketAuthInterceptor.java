package com.jira.backend.websocket.interceptor;

import com.jira.backend.config.JwtUtil;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.Collections;

@Component
@RequiredArgsConstructor
@Slf4j
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final JwtUtil jwtUtil;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor == null) return message;

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                throw new IllegalArgumentException("Missing or invalid Authorization header on STOMP CONNECT");
            }

            String token = authHeader.substring(7);

            if (!jwtUtil.isTokenValid(token)) {
                throw new IllegalArgumentException("Invalid JWT token on STOMP CONNECT");
            }

            Claims claims = jwtUtil.extractClaims(token);
            String uid = claims.getSubject();

            // Set principal so Spring knows who this connection belongs to.
            // This is what makes convertAndSendToUser(uid, ...) work correctly.
            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(uid, null, Collections.emptyList());

            accessor.setUser(auth);
            log.debug("WebSocket CONNECT authenticated for uid: {}", uid);
        }

        return message;
    }
}