# 天虹紧固件 FastAPI 服务部署指南

## 问题诊断

### 当前状态
- **服务器**: 47.110.72.148
- **端口冲突**: 9000端口被Cloud IDE WebSocket占用
- **解决方案**: 使用8080端口运行FastAPI服务

## 快速启动（3步完成）

### 步骤1：启动 FastAPI 服务

```bash
# 方法1：使用自动检测脚本（推荐）
bash start_service_v2.sh

# 方法2：手动启动
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

# 方法3：直接执行（如果当前目录正确）
python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080
```

### 步骤2：验证服务启动

```bash
# 检查进程
ps aux | grep uvicorn | grep -v grep

# 检查端口
netstat -tlnp | grep 8080

# 测试接口
curl http://localhost:8080/health
curl http://localhost:8080/api/test
```

### 步骤3：配置 Nginx 反向代理

#### 3.1 创建 Nginx 配置文件

```bash
# 编辑配置文件
vim /etc/nginx/sites-available/tnho-fasteners
```

#### 3.2 配置内容

```nginx
server {
    listen 80;
    server_name 47.110.72.148 tnho-fasteners.com;

    # 日志
    access_log /var/log/nginx/tnho-fasteners-access.log;
    error_log /var/log/nginx/tnho-fasteners-error.log;

    # 上传文件大小限制
    client_max_body_size 10M;

    # 反向代理到FastAPI服务（8080端口）
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时配置（视频生成需要更长时间）
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    # 静态文件直接服务
    location /assets/ {
        proxy_pass http://127.0.0.1:8080/assets/;
        expires 30d;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        access_log off;
    }
}
```

#### 3.3 启用配置

```bash
# 创建符号链接
ln -s /etc/nginx/sites-available/tnho-fasteners /etc/nginx/sites-enabled/

# 测试配置
nginx -t

# 重启Nginx
systemctl restart nginx
```

#### 3.4 配置防火墙（如果需要）

```bash
# 开放8080端口（仅本地访问，由Nginx转发）
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# 或者使用iptables
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

## 验证部署

### 1. 本地测试

```bash
# 测试健康检查
curl http://localhost:8080/health

# 测试脚本生成
curl -X POST http://localhost:8080/api/generate-script \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "螺母",
    "product_image_url": "https://example.com/image.jpg",
    "usage_scenario": "建筑工地",
    "theme_direction": "高品质"
  }'
```

### 2. 外部测试

```bash
# 通过Nginx访问
curl http://47.110.72.148/health
curl http://tnho-fasteners.com/health
```

### 3. 小程序测试

1. 打开微信开发者工具
2. 编译小程序
3. 测试图片上传功能
4. 测试视频生成流程

## 常见问题排查

### 问题1：服务启动失败

```bash
# 查看日志
tail -50 /tmp/fastapi.log

# 检查端口占用
netstat -tlnp | grep 8080

# 检查依赖
pip3 install -r requirements.txt
```

### 问题2：Nginx 404错误

```bash
# 检查Nginx配置
nginx -t

# 检查Nginx日志
tail -50 /var/log/nginx/tnho-fasteners-error.log

# 重启Nginx
systemctl restart nginx
```

### 问题3：小程序连接被拒绝

1. 检查防火墙规则
2. 确认Nginx已启动：`systemctl status nginx`
3. 确认FastAPI已启动：`ps aux | grep uvicorn`
4. 检查小程序配置中的 `apiBaseUrl`

## 服务管理命令

```bash
# 启动服务
bash start_service_v2.sh

# 停止服务
pkill -f "uvicorn.*src.main:app"

# 查看日志
tail -f /tmp/fastapi.log

# 重启服务
pkill -f "uvicorn.*src.main:app"
sleep 2
bash start_service_v2.sh

# 查看服务状态
ps aux | grep uvicorn
netstat -tlnp | grep 8080
```

## 架构说明

```
┌─────────────┐
│ 微信小程序  │
└──────┬──────┘
       │ HTTP
       ▼
┌─────────────┐      ┌──────────────┐
│   Nginx     │ ───▶ │  FastAPI     │
│  (端口80)   │      │  (端口8080)  │
└─────────────┘      └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   火山方舟    │
                    │  (AI服务)    │
                    └──────────────┘
```

## 目录结构

```
/workspace/projects/
├── src/
│   ├── main.py                 # FastAPI 主程序
│   ├── agents/                 # Agent 定义
│   ├── tools/                  # 工具函数
│   └── api/                    # API 路由
├── assets/                     # 静态资源目录
│   └── uploads/                # 上传文件存储
├── start_service_v2.sh         # 服务启动脚本
├── DEPLOYMENT.md               # 本部署文档
└── nginx-config.conf           # Nginx 配置参考
```

## 联系支持

如遇问题，请提供以下信息：
1. 错误截图或日志
2. 执行的命令
3. 服务器操作系统版本：`cat /etc/os-release`
4. Python版本：`python3 --version`
5. Nginx版本：`nginx -v`
