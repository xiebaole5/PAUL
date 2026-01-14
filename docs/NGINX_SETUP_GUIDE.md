# Nginx 反向代理配置指南

## 问题诊断

### 当前状态

✅ **域名可以访问**
```bash
$ curl https://tnho-fasteners.com/health
{"status":"ok"}
```

❌ **8080 端口无法从外网访问**
```bash
$ curl http://115.190.192.22:8080/api/wechat/test
# 无响应或超时
```

❌ **企业微信接口返回 522 错误**
```bash
$ curl https://tnho-fasteners.com/api/wechat/test
error code: 522
```

### 问题原因

**Cloudflare 无法连接到源服务器的 8080 端口**

虽然域名可以访问 80 端口，但是 8080 端口可能被：
- 防火墙阻止
- 安全组规则限制
- 服务器配置问题

**522 错误**: Cloudflare 无法与源站建立连接

## 解决方案：配置 Nginx 反向代理

通过配置 Nginx 反向代理，让所有通过 80 端口的请求（包括 Cloudflare 的代理请求）转发到本地的 8080 端口，从而绕过端口访问限制。

## 配置步骤

### 步骤 1: 安装 Nginx

在服务器上执行：

```bash
# 更新包管理器
apt update

# 安装 Nginx
apt install -y nginx

# 验证安装
nginx -v
```

### 步骤 2: 创建配置文件

创建 Nginx 配置文件 `/etc/nginx/sites-available/tnho-api`:

```bash
nano /etc/nginx/sites-available/tnho-api
```

复制以下内容到文件中：

```nginx
server {
    listen 80;
    server_name tnho-fasteners.com 115.190.192.22;

    # 文件上传大小限制
    client_max_body_size 10m;

    # 超时设置
    proxy_connect_timeout 60s;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;

    # 日志配置
    access_log /var/log/nginx/tnho-access.log;
    error_log /var/log/nginx/tnho-error.log;

    location / {
        # 反向代理到本地 FastAPI 服务
        proxy_pass http://localhost:8080;

        # 代理头设置
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持（如果需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

保存文件：按 `Ctrl+X`，然后按 `Y`，最后按 `Enter`

### 步骤 3: 启用配置

```bash
# 创建软链接，启用配置
ln -s /etc/nginx/sites-available/tnho-api /etc/nginx/sites-enabled/

# 删除默认配置（可选，避免端口冲突）
rm /etc/nginx/sites-enabled/default

# 测试配置是否正确
nginx -t
```

应该看到：
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 步骤 4: 重启 Nginx

```bash
# 重启 Nginx 服务
systemctl restart nginx

# 检查 Nginx 状态
systemctl status nginx

# 查看 Nginx 日志
tail -f /var/log/nginx/tnho-access.log
```

### 步骤 5: 验证配置

```bash
# 测试健康检查接口
curl http://localhost/health

# 应该返回: {"status":"ok"}

# 测试企业微信接口
curl http://localhost/api/wechat/test

# 应该返回: {"status":"ok","message":"企业微信接口正常",...}
```

### 步骤 6: 从外网测试

```bash
# 测试域名访问
curl https://tnho-fasteners.com/health

# 应该返回: {"status":"ok"}

# 测试企业微信接口
curl https://tnho-fasteners.com/api/wechat/test

# 应该返回: {"status":"ok","message":"企业微信接口正常",...}
```

### 步骤 7: 在企业微信中验证

1. 登录企业微信管理后台
2. 找到"TNHO全能营销助手"机器人
3. 点击"接收消息" -> "设置API接收"
4. 点击"验证"按钮
5. 应该显示"验证成功"

## 常用命令

### Nginx 管理命令

```bash
# 启动 Nginx
systemctl start nginx

# 停止 Nginx
systemctl stop nginx

# 重启 Nginx
systemctl restart nginx

# 重新加载配置（不中断服务）
systemctl reload nginx

# 查看 Nginx 状态
systemctl status nginx

# 查看实时日志
tail -f /var/log/nginx/tnho-access.log
tail -f /var/log/nginx/tnho-error.log
```

### FastAPI 服务管理命令

```bash
# 重启 FastAPI 服务
cd /workspace/projects && ./scripts/service.sh restart

# 查看服务状态
cd /workspace/projects && ./scripts/service.sh status

# 查看服务日志
cd /workspace/projects && ./scripts/service.sh logs
```

## 故障排查

### 问题 1: Nginx 配置测试失败

**错误信息**: `nginx: configuration file test failed`

**解决**:
1. 检查配置文件语法: `nginx -t`
2. 查看错误详情，修正配置错误
3. 确保 80 端口没有被占用: `netstat -tuln | grep :80`

### 问题 2: Nginx 无法启动

**错误信息**: `Failed to start nginx.service`

**解决**:
1. 检查端口占用:
   ```bash
   netstat -tuln | grep :80
   # 如果端口被占用，停止占用进程
   ```

2. 检查配置文件:
   ```bash
   nginx -t
   ```

3. 查看 Nginx 错误日志:
   ```bash
   cat /var/log/nginx/error.log
   ```

### 问题 3: 代理返回 502 Bad Gateway

**错误信息**: `502 Bad Gateway`

**原因**: FastAPI 服务未运行或无法连接到 8080 端口

**解决**:
1. 检查 FastAPI 服务是否运行:
   ```bash
   ./scripts/service.sh status
   ```

2. 检查 8080 端口是否监听:
   ```bash
   netstat -tuln | grep 8080
   ```

3. 测试本地访问:
   ```bash
   curl http://localhost:8080/health
   ```

4. 如果服务未运行，重启服务:
   ```bash
   ./scripts/service.sh restart
   ```

### 问题 4: Cloudflare 返回 522 错误

**错误信息**: `error code: 522`

**原因**: Cloudflare 无法连接到源站

**解决**:
1. 确保 Nginx 正在运行:
   ```bash
   systemctl status nginx
   ```

2. 确保 FastAPI 服务正在运行:
   ```bash
   ./scripts/service.sh status
   ```

3. 确保 80 端口可以从外网访问:
   ```bash
   # 从外网测试
   curl http://115.190.192.22/health
   ```

4. 检查防火墙规则:
   ```bash
   iptables -L -n | grep 80
   ```

5. 如果使用云服务器，检查安全组规则，确保 80 端口开放

### 问题 5: 文件上传失败

**错误信息**: `413 Request Entity Too Large`

**解决**:
在 Nginx 配置中增加文件上传大小限制：
```nginx
client_max_body_size 20m;  # 修改为更大的值
```

然后重新加载配置：
```bash
nginx -t && systemctl reload nginx
```

## 配置文件说明

### 完整配置文件

```nginx
server {
    listen 80;
    server_name tnho-fasteners.com 115.190.192.22;

    # 文件上传大小限制（支持上传图片和视频）
    client_max_body_size 10m;

    # 超时设置（视频生成可能需要较长时间）
    proxy_connect_timeout 60s;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;

    # 日志配置
    access_log /var/log/nginx/tnho-access.log;
    error_log /var/log/nginx/tnho-error.log;

    location / {
        # 反向代理到本地 FastAPI 服务
        proxy_pass http://localhost:8080;

        # 代理头设置
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 配置参数说明

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `client_max_body_size` | 最大请求体大小（文件上传） | 10m - 20m |
| `proxy_connect_timeout` | 连接超时时间 | 60s |
| `proxy_read_timeout` | 读取超时时间 | 300s |
| `proxy_send_timeout` | 发送超时时间 | 300s |

## 安全建议

1. **限制访问来源**
   - 在生产环境中，只允许 Cloudflare IP 访问
   - 防止直接访问服务器 IP

2. **启用 HTTPS**
   - 配置 SSL 证书（Let's Encrypt 或 Cloudflare Origin Certificate）
   - 强制重定向 HTTP 到 HTTPS

3. **启用防火墙**
   - 只开放必要的端口（80, 443）
   - 限制 8080 端口的访问

4. **定期更新**
   - 保持 Nginx 和系统更新
   - 定期检查安全日志

## 后续优化

### 配置 HTTPS（可选）

如果需要启用 HTTPS，可以配置 SSL 证书：

```nginx
server {
    listen 443 ssl;
    server_name tnho-fasteners.com;

    ssl_certificate /etc/nginx/ssl/tnho.crt;
    ssl_certificate_key /etc/nginx/ssl/tnho.key;

    location / {
        proxy_pass http://localhost:8080;
        ...
    }
}

server {
    listen 80;
    server_name tnho-fasteners.com;
    return 301 https://$server_name$request_uri;
}
```

### 配置负载均衡（可选）

如果有多个后端服务，可以配置负载均衡：

```nginx
upstream fastapi_backend {
    server localhost:8080;
    # server localhost:8081;
    # server localhost:8082;
}

server {
    listen 80;
    server_name tnho-fasteners.com;

    location / {
        proxy_pass http://fastapi_backend;
        ...
    }
}
```

## 联系支持

如果遇到问题，请提供以下信息：

1. Nginx 版本: `nginx -v`
2. Nginx 状态: `systemctl status nginx`
3. Nginx 错误日志: `cat /var/log/nginx/error.log`
4. FastAPI 服务状态: `./scripts/service.sh status`
5. 错误信息截图

## 更新日志

### 2025-01-14
- ✅ 诊断出 8080 端口无法从外网访问的问题
- ✅ 创建 Nginx 反向代理配置指南
- ✅ 提供详细的故障排查步骤
- ⚠️ 等待用户执行 Nginx 配置
