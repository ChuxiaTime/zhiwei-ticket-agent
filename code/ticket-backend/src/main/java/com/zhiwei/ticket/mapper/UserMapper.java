package com.zhiwei.ticket.mapper;


import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhiwei.ticket.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
 public interface UserMapper extends BaseMapper<User> {
}
