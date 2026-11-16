package com.zhiwei.ticket.controller;


import com.zhiwei.ticket.common.Result;
import com.zhiwei.ticket.dto.KnowledgeAddRequest;
import com.zhiwei.ticket.entity.Knowledge;
import com.zhiwei.ticket.service.KnowledgeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/knowledge")
public class KnowledgeController {

    @Autowired
    private KnowledgeService knowledgeService;

    @PostMapping
    public Result<Knowledge> addKnowledge(@RequestBody KnowledgeAddRequest request) {
        return knowledgeService.addKnowledge(request);
    }


    @GetMapping
    public Result<List<Knowledge>> getKnowledgeList() {
        return knowledgeService.getKnowledgeList();
    }

    @DeleteMapping("/{id}")
    public Result<Void> deleteKnowledge(@PathVariable long id) {
        return knowledgeService.deleteKnowledge(id);
    }

}
