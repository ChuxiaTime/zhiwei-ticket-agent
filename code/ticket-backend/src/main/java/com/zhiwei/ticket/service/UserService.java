package com.zhiwei.ticket.service;


import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.zhiwei.ticket.dto.LoginRequest;
import com.zhiwei.ticket.dto.LoginResponse;
import com.zhiwei.ticket.entity.User;
import com.zhiwei.ticket.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    @Autowired
    private UserMapper userMapper;

    public LoginResponse login(LoginRequest loginRequest) {
        User user = userMapper.selectOne(Wrappers.lambdaQuery(User.class).eq(User::getUsername, loginRequest.getUsername()));
        if (user == null) {
           return null;
        }
        if (!user.getPassword().equals(loginRequest.getPassword())) {
            return null;
        }
        StpUtil.login(user.getId());
        String token = StpUtil.getTokenValue();
        return LoginResponse.form(user, token);
    }
}
