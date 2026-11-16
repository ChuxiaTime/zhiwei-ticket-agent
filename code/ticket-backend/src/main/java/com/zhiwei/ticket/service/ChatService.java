package com.zhiwei.ticket.service;


import com.alibaba.fastjson2.JSON;
import com.zhiwei.ticket.client.AgentClient;
import com.zhiwei.ticket.common.Result;
import com.zhiwei.ticket.dto.ChatRequest;
import com.zhiwei.ticket.dto.ChatResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ChatService {

    @Autowired
    private AgentClient agentClient;


    public Result<ChatResponse> chat(ChatRequest chatRequest) {
        //调用AI agent服务
        Object result = agentClient.chat(chatRequest);
        ChatResponse response = JSON.parseObject(JSON.toJSONString(result), ChatResponse.class);
        return Result.success(response);
    }

}
