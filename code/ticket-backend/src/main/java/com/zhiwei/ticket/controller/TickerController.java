package com.zhiwei.ticket.controller;


import com.zhiwei.ticket.common.PageData;
import com.zhiwei.ticket.common.Result;
import com.zhiwei.ticket.dto.TicketSubmitRequest;
import com.zhiwei.ticket.dto.TicketUpdateRequest;
import com.zhiwei.ticket.entity.Ticket;
import com.zhiwei.ticket.service.TicketService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/ticket")
public class TickerController {

    @Autowired
    private TicketService ticketService;

    @GetMapping
    public Result<PageData<Ticket>> getTicket(Integer page, Integer size, String status, String dateFrom, String dateTo) {
        return Result.success(ticketService.getPageData(page, size, status, dateFrom, dateTo));
    }

    @GetMapping("/{id}")
    public Result<Ticket> getTicketDetail(@PathVariable Long id) {
        Ticket ticket = ticketService.getTicketDetail(id);
        return Result.success(ticket);
    }

    @PostMapping
    public Result<Ticket> submit(@RequestBody TicketSubmitRequest request) {
        return Result.success(ticketService.submit(request));
    }

    @PutMapping("/{id}")
    public Result<Ticket> update(@PathVariable Long id, @RequestBody TicketUpdateRequest request) {
        return ticketService.updateTicket(id, request);
    }
}
