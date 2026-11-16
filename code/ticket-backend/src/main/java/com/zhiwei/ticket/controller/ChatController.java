package com.zhiwei.ticket.controller;


import com.zhiwei.ticket.common.Result;
import com.zhiwei.ticket.dto.ChatRequest;
import com.zhiwei.ticket.dto.ChatResponse;
import com.zhiwei.ticket.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/chat")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @PostMapping
    public Result<ChatResponse> chat(@RequestBody ChatRequest chatRequest) {
        return chatService.chat(chatRequest);
    }

}
