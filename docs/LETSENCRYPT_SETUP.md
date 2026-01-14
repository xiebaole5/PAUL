# Let's Encrypt 证书配置指南

## 概述

本指南介绍如何使用 Let's Encrypt 为 `tnho-fasteners.com` 配置免费的 HTTPS 证书。

## 前提条件

1. ✅ DNS 服务器已修改为 Cloudflare（`hassan.ns.cloudflare.com` 和 `aria.ns.cloudflare.com`）
2. ✅ DNS 已开始生效（可以使用 `nslookup -type=NS tnho-fasteners.com` 确认）
3. ✅ 服务器可以访问互联网
4. ✅ 防火墙已开放端口 80（用于 Let's Encrypt 域名验证）

## 快速开始

### 方法 1：使用自动化脚本（推荐）

1. **SSH 登录到服务器**
   ```bash
   ssh root@47.110.72.148
   ```

2. **进入项目目录**
   ```bash
   cd /workspace/projects
   ```

3. **赋予脚本执行权限**
   ```bash
   chmod +x scripts/setup_letsencrypt.sh
   ```

4. **运行配置脚本**
   ```bash
   bash scripts/setup_letsencrypt.sh
   ```

5. **按照提示操作**
   - 脚本会自动检查域名解析
   - 安装 Certbot
   - 申请 Let's Encrypt 证书
   - 配置 Nginx
   - 设置证书自动续期

6. **验证配置**
   ```bash
   # 检查证书
   certbot certificates

   # 测试 HTTPS 访问
   curl -I https://tnho-fasteners.com
   ```

---

### 方法 2：手动配置（高级用户）

#### 1. 安装 Certbot

```bash
apt-get update
apt-get install -y certbot
```

#### 2. 申请证书

确保端口 80 未被占用：
```bash
# 停止 Nginx
pkill nginx

# 检查端口 80
netstat -tlnp | grep :80
```

申请证书：
```bash
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email xiebaole5@gmail.com \
    -d tnho-fasteners.com \
    -d www.tnho-fasteners.com
```

#### 3. 配置 Nginx

创建或编辑 `/etc/nginx/sites-available/tnho-https.conf`：

```nginx
server {
    listen 80;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # HTTP 到 HTTPS 重定向
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Let's Encrypt 证书路径
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # SSL 会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 其他安全头部
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # 日志
    access_log /var/log/nginx/tnho-https-access.log;
    error_log /var/log/nginx/tnho-https-error.log;

    # 反向代理到 FastAPI 应用
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # 健康检查接口
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        access_log off;
    }
}
```

创建符号链接：
```bash
ln -sf /etc/nginx/sites-available/tnho-https.conf /etc/nginx/sites-enabled/tnho-https.conf
```

测试配置：
```bash
nginx -t
```

重启 Nginx：
```bash
pkill nginx && nginx
```

#### 4. 设置证书自动续期

```bash
# 添加 crontab 任务
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && nginx -s reload") | crontab -
```

---

## 配置 Cloudflare SSL/TLS 模式

证书配置完成后，需要在 Cloudflare 控制台配置 SSL/TLS 模式：

1. **登录 Cloudflare 控制台**
   - 访问：https://dash.cloudflare.com/

2. **进入域名设置**
   - 点击域名 `tnho-fasteners.com`
   - 点击左侧菜单 **SSL/TLS** → **Overview**

3. **选择 SSL/TLS 模式**
   - 选择 **Full** 或 **Full (strict)**
   - ✅ **Full**：Cloudflare 到服务器使用加密，但不验证服务器证书（推荐，兼容性最好）
   - ✅ **Full (strict)**：Cloudflare 到服务器使用加密，并验证服务器证书（安全性最高）

---

## 验证配置

### 1. 检查证书信息

```bash
certbot certificates
```

应该显示：
```
Certificate Name: tnho-fasteners.com
  Domains: tnho-fasteners.com www.tnho-fasteners.com
  Expiry Date: YYYY-MM-DD
  Certificate Path: /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem
  Private Key Path: /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem
```

### 2. 测试 HTTPS 访问

```bash
# 测试 HTTPS
curl -I https://tnho-fasteners.com

# 测试 HTTP 到 HTTPS 重定向
curl -I http://tnho-fasteners.com

# 应该返回 301 重定向
```

### 3. 在线测试

使用以下工具测试 HTTPS 配置：
- https://www.ssllabs.com/ssltest/
- https://crt.sh/

---

## 常见问题

### 1. 证书申请失败

**错误：**
```
Challenge failed for domain tnho-fasteners.com
```

**解决方案：**
- 确保域名 DNS 正确解析到服务器
- 检查防火墙是否开放端口 80
- 检查 Nginx 或其他程序是否占用端口 80
- 等待 DNS 传播完成（可能需要几分钟到几小时）

### 2. 端口 80 被占用

**错误：**
```
Binding to 0.0.0.0:80 failed (98: Address already in use)
```

**解决方案：**
```bash
# 查看占用端口 80 的进程
netstat -tlnp | grep :80

# 停止 Nginx
pkill nginx

# 或者停止其他占用端口的程序
```

### 3. Nginx 配置测试失败

**错误：**
```
nginx: configuration file test failed
```

**解决方案：**
```bash
# 检查配置错误
nginx -t

# 查看 Nginx 错误日志
tail -f /var/log/nginx/error.log
```

### 4. 浏览器显示证书错误

**可能原因：**
- Cloudflare SSL/TLS 模式设置不正确
- 证书未正确安装
- DNS 传播未完成

**解决方案：**
- 在 Cloudflare 设置 SSL/TLS 模式为 Full
- 等待 DNS 传播完成
- 检查 Nginx 配置中的证书路径

---

## 证书续期

Let's Encrypt 证书有效期为 90 天，但脚本已设置自动续期。

### 手动续期

```bash
# 测试续期（不实际续期）
certbot renew --dry-run

# 实际续期
certbot renew

# 续期后重启 Nginx
nginx -s reload
```

### 自动续期

脚本已添加 crontab 任务，每天凌晨 3 点自动检查并续期：
```bash
# 查看 crontab 任务
crontab -l
```

---

## 文件位置

### 证书文件
```
/etc/letsencrypt/live/tnho-fasteners.com/
├── fullchain.pem    # 证书链
├── privkey.pem      # 私钥
├── cert.pem         # 证书
└── chain.pem        # 中间证书
```

### Nginx 配置
```
/etc/nginx/sites-available/tnho-https.conf    # 配置文件
/etc/nginx/sites-enabled/tnho-https.conf      # 符号链接
/etc/nginx/ssl/                               # 备份证书（如果有的话）
```

### 日志文件
```
/var/log/nginx/tnho-https-access.log          # 访问日志
/var/log/nginx/tnho-https-error.log           # 错误日志
/var/log/letsencrypt/                         # Let's Encrypt 日志
```

---

## 支持和帮助

如果遇到问题，可以：
1. 检查 Nginx 日志：`tail -f /var/log/nginx/error.log`
2. 检查 Let's Encrypt 日志：`cat /var/log/letsencrypt/letsencrypt.log`
3. 测试证书：`certbot certificates`
4. 重启 Nginx：`pkill nginx && nginx`
