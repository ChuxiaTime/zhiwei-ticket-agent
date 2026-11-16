package com.zhiwei.ticket.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 知识库实体。
 *
 * 原始文本落 MySQL；标题、正文、分类和向量同步写入 Milvus，
 * 检索时直接使用 Milvus 返回的文本字段。
 */
@Data
@TableName("t_knowledge")
public class Knowledge {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;
    private String content;
    private String category;
    private Long creatorId;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
