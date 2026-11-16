package com.zhiwei.ticket.dto;


import lombok.Data;

@Data
public class KnowledgeAddRequest {

    private Long id;
    private String title;
    private String content;
    private String category;

}
