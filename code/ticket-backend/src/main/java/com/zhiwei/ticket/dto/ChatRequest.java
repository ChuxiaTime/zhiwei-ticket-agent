package com.zhiwei.ticket.dto;


import lombok.Data;

@Data
public class ChatRequest {
    private String sessionId;
    private String message;
}
