package com.zhiwei.ticket.dto;


import com.alibaba.fastjson2.annotation.JSONField;
import lombok.Data;

@Data
public class AIAnalyzeResponse {
    @JSONField(name = "fault_type")
    private String faultType;
    private String suggestion;
    @JSONField(name = "similar_tickets")
    private String similarTickets;
    @JSONField(name = "similar_knowledge")
    private String similarKnowledge;
}
