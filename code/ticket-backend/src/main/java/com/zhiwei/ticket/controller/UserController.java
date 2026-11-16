package com.zhiwei.ticket.controller;


import cn.dev33.satoken.annotation.SaIgnore;
import com.zhiwei.ticket.common.Result;
import com.zhiwei.ticket.dto.LoginRequest;
import com.zhiwei.ticket.dto.LoginResponse;
import com.zhiwei.ticket.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user")
public class UserController {


    @Autowired
    private UserService userService;

    @RequestMapping("/login")
    @SaIgnore
    public Result<LoginResponse> login(@RequestBody LoginRequest loginRequest) {
        return Result.success(userService.login(loginRequest));
    }

}
