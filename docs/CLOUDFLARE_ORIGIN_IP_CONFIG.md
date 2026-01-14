# Cloudflare 源站 IP 配置指南

## 当前状态

✅ 域名已备案完成
✅ FastAPI 服务运行正常（端口 8080）
✅ 小程序和企业微信配置已更新为使用域名
⚠️ 需要配置 Cloudflare 源站 IP

## 问题说明

通过域名访问服务时返回 403 或连接错误，原因是 Cloudflare 源站配置指向了旧的 IP 地址（47.110.72.148），而当前服务运行在新的 IP 地址（115.190.192.22）。

## 解决方案

### 方法一：在 Cloudflare 控制台更新源站 IP（推荐）

1. **登录 Cloudflare 控制台**
   - 访问 https://dash.cloudflare.com/
   - 选择 tnho-fasteners.com 域名

2. **找到 DNS 记录**
   - 导航到 `DNS` -> `Records`
   - 找到 A 记录（@ 或 tnho-fasteners.com）
   - 找到 CNAME 记录（www，如果有的话）

3. **更新源站 IP**
   - 点击 A 记录的编辑按钮
   - 将 `Content` 字段从 `47.110.72.148` 改为 `115.190.192.22`
   - 确保 `Proxy status` 为 `Proxied`（橙色云朵）
   - 点击 `Save` 保存

4. **验证配置**
   ```bash
   # 等待 DNS 传播（通常 5-10 分钟）
   curl https://tnho-fasteners.com/health
   # 应该返回: {"status":"ok"}
   ```

### 方法二：使用临时 IP 地址（不推荐）

如果暂时无法访问 Cloudflare 控制台，可以使用临时 IP 地址访问：

- 小程序配置：保持使用域名（已配置为 https://tnho-fasteners.com）
- 企业微信配置：保持使用域名（回调 URL：https://tnho-fasteners.com/api/wechat/callback）
- 临时测试：直接访问 http://115.190.192.22:8080/health

## 服务信息

- **当前服务器 IP**: 115.190.192.22
- **服务端口**: 8080
- **健康检查接口**: /health
- **小程序 API 地址**: https://tnho-fasteners.com
- **企业微信回调 URL**: https://tnho-fasteners.com/api/wechat/callback

## Cloudflare SSL/TLS 配置

由于当前没有配置 Nginx SSL 证书，建议使用 **Flexible** 模式：

1. **登录 Cloudflare 控制台**
2. **导航到 SSL/TLS -> Overview**
3. **选择模式**: `Flexible`（橙色云朵）
   - Flexible: Cloudflare 接受 HTTPS，但使用 HTTP 与源站通信
   - Full: Cloudflare 接受 HTTPS，并使用 HTTPS 与源站通信（需要源站配置 SSL 证书）
   - Full (strict): Full + 验证源站证书（最严格）

## 如果使用 Full 模式

如果需要使用 Full 模式，需要在服务器上配置 Nginx SSL 证书：

1. **安装 Nginx**
   ```bash
   apt update
   apt install -y nginx
   ```

2. **生成自签名证书（临时方案）**
   ```bash
   mkdir -p /etc/nginx/ssl
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout /etc/nginx/ssl/tnho.key \
     -out /etc/nginx/ssl/tnho.crt \
     -subj "/CN=tnho-fasteners.com"
   ```

3. **配置 Nginx 反向代理**
   ```nginx
   server {
       listen 443 ssl;
       server_name tnho-fasteners.com;

       ssl_certificate /etc/nginx/ssl/tnho.crt;
       ssl_certificate_key /etc/nginx/ssl/tnho.key;

       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

4. **重启 Nginx**
   ```bash
   nginx -t && nginx -s reload
   ```

5. **在 Cloudflare 切换到 Full 模式**

## 验证步骤

1. **测试健康检查接口**
   ```bash
   curl https://tnho-fasteners.com/health
   # 应该返回: {"status":"ok"}
   ```

2. **测试企业微信接口**
   ```bash
   curl https://tnho-fasteners.com/api/wechat/test
   # 应该返回: {"status":"ok", ...}
   ```

3. **测试小程序接口**
   ```bash
   curl -X POST https://tnho-fasteners.com/api/generate-script \
     -H "Content-Type: application/json" \
     -d '{"theme":"品质保证","duration":20}'
   ```

## 生产环境建议

1. **使用正式 SSL 证书**
   - 使用 Let's Encrypt 申请正式证书
   - 或使用 Cloudflare Origin Certificate（推荐）

2. **配置防火墙规则**
   - 只允许 Cloudflare IP 访问 8080 端口
   - 限制外部直接访问 8080 端口

3. **启用 Cloudflare 安全功能**
   - Bot Fight Mode（注意：可能影响小程序访问）
   - Rate Limiting
   - Web Application Firewall (WAF)

## 故障排查

### 问题 1: 403 Forbidden

**原因**: Cloudflare Bot Fight Mode 或安全规则阻止了请求

**解决**:
- 在 Cloudflare 控制台关闭 Bot Fight Mode
- 添加白名单规则

### 问题 2: 525 SSL Handshake Failed

**原因**: Cloudflare Full 模式下无法与源站建立 SSL 连接

**解决**:
- 切换到 Flexible 模式
- 或在源站配置正确的 SSL 证书

### 问题 3: 520 Web Server Returned an Unknown Error

**原因**: 源站服务器错误或响应超时

**解决**:
- 检查 FastAPI 服务是否正常运行
- 检查防火墙规则
- 检查 Nginx 配置（如果使用）

## 联系支持

如果遇到问题，请提供以下信息：
- 域名: tnho-fasteners.com
- 源站 IP: 115.190.192.22
- 服务端口: 8080
- 错误日志: `./scripts/service.sh logs`
