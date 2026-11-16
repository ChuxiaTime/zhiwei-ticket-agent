package com.zhiwei.ticket.mapper;


import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhiwei.ticket.entity.Ticket;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TicketMapper extends BaseMapper<Ticket> {
}
