-- 智维 · 企业 IT 智能工单平台 数据库初始化脚本
-- 用法：mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/init.sql
-- 注意：三个测试账号的密码均为 123456

CREATE DATABASE IF NOT EXISTS zhiwei_ticket
  CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE zhiwei_ticket;

CREATE TABLE IF NOT EXISTS t_user (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  password VARCHAR(128) NOT NULL,
  real_name VARCHAR(64) DEFAULT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'employee',
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS t_ticket (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  fault_type VARCHAR(32) DEFAULT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
  submitter_id BIGINT DEFAULT NULL,
  assignee_id BIGINT DEFAULT NULL,
  ai_suggestion TEXT,
  similar_tickets TEXT,
  similar_knowledge TEXT,
  resolution TEXT,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS t_knowledge (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  category VARCHAR(64) DEFAULT NULL,
  creator_id BIGINT DEFAULT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试账号：密码统一为 123456
INSERT INTO t_user (id, username, password, real_name, role) VALUES
  (1, 'admin',    '123456', '系统管理员', 'admin'),
  (2, 'employee', '123456', '普通员工',   'employee'),
  (3, 'engineer', '123456', '运维工程师', 'engineer')
ON DUPLICATE KEY UPDATE
  password  = VALUES(password),
  real_name = VALUES(real_name),
  role      = VALUES(role);

-- 示例知识
INSERT IGNORE INTO t_knowledge (id, title, content, category, creator_id) VALUES
  (1, '打印机脱机处理步骤',
      '1.检查USB/网络连接 2.清除打印队列 3.重启Print Spooler服务 4.重新添加打印机',
      'hardware', 1);

-- 示例工单
INSERT IGNORE INTO t_ticket
  (id, title, description, fault_type, status, submitter_id, ai_suggestion, resolution) VALUES
  (1, '办公室电脑无法连接内网',
      '今早开机后无法访问公司内网网站，其他同事正常，已重启电脑无效',
      'unknown', 'PENDING', 1, NULL, NULL),
  (2, '打印机无法打印',
      '三楼打印机显示脱机，重启打印机无效',
      'hardware', 'PENDING', 1, NULL, NULL),
  (3, 'VPN连接频繁断开',
      '使用公司VPN办公时每隔几分钟就断开，需要重新登录，网络正常',
      'network', 'PENDING', 1,
      '知识库与工单中均未检索到相似故障的排查资料，无法基于现有资料给出具体命令或步骤。建议先做基础确认：记录断开的具体时间间隔和频率，确认是否仅在使用公司VPN时出现、本地网络是否稳定；检查VPN客户端版本及日志中是否有报错信息。由于缺乏可参考的解决方案，建议将此工单转交网络运维人工排查，并附上断开频率、客户端日志等现场信息以便定位。',
      NULL);
