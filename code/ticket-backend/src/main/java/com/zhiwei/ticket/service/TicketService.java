package com.zhiwei.ticket.service;


import cn.dev33.satoken.stp.StpUtil;
import com.alibaba.fastjson2.JSON;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhiwei.ticket.client.AgentClient;
import com.zhiwei.ticket.common.PageData;
import com.zhiwei.ticket.common.Result;
import com.zhiwei.ticket.dto.AIAnalyzeResponse;
import com.zhiwei.ticket.dto.TicketSubmitRequest;
import com.zhiwei.ticket.dto.TicketUpdateRequest;
import com.zhiwei.ticket.entity.Ticket;
import com.zhiwei.ticket.mapper.TicketMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Slf4j
@Service
public class TicketService {

    @Autowired
    private TicketMapper ticketMapper;

    @Autowired
    private AgentClient agentClient;

    public PageData<Ticket> getPageData(int page, int size, String status, String dateFrom, String dateTo) {
        QueryWrapper<Ticket> queryWrapper = new QueryWrapper<Ticket>();
        if (status != null && !status.equals("")) {
            queryWrapper.eq("status", status);
        }
        if (dateFrom != null && !dateFrom.equals("")) {
            queryWrapper.ge("create_time", dateFrom + " 00:00:00");
        }
        if (dateTo != null && !dateTo.equals("")) {
            queryWrapper.le("create_time", dateTo + " 23:59:59");
        }
        Page<Ticket> ticketPage = ticketMapper.selectPage(new Page<>(page, size), queryWrapper);
        PageData<Ticket> pageData = new PageData<>();
        pageData.setTotal(ticketPage.getTotal());
        pageData.setList(ticketPage.getRecords());
        return pageData;
    }


    public Ticket getTicketDetail(Long ticketId) {
        Ticket ticket = ticketMapper.selectById(ticketId);
        return ticket;
    }


    public Ticket submit(TicketSubmitRequest request) {
        Ticket ticket = new Ticket();
        ticket.setTitle(request.getTitle());
        ticket.setDescription(request.getDescription());
        ticket.setFaultType(request.getFaultType());
        ticket.setStatus("PENDING");
        ticket.setSubmitterId(StpUtil.getLoginIdAsLong());
        ticket.setCreateTime(LocalDateTime.now());
        ticket.setUpdateTime(LocalDateTime.now());
        ticketMapper.insert(ticket);
        //调用AI agent
        Object result = agentClient.analyzeTicket(ticket);
        AIAnalyzeResponse response = JSON.parseObject(JSON.toJSONString(result), AIAnalyzeResponse.class);
        ticket.setSimilarTickets(response.getSimilarTickets());
        ticket.setSimilarKnowledge(response.getSimilarKnowledge());
        ticket.setFaultType(response.getFaultType());
        ticket.setAiSuggestion(response.getSuggestion());
        ticketMapper.updateById(ticket);
        return ticket;
    }


    public Result<Ticket> updateTicket(Long id, TicketUpdateRequest req) {
        Ticket ticket = ticketMapper.selectById(id);
        ticket.setResolution(req.getResolution());
        ticket.setStatus(req.getStatus());
        ticketMapper.updateById(ticket);
        Boolean ok = agentClient.updateTicket(ticket);
        log.info("update ticket ok:{}", ok);
        return Result.success(ticket);

    }

}
