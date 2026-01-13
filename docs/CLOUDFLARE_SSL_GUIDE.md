# Cloudflare SSL 证书部署指南

本文档介绍如何使用 Cloudflare Origin Certificate 为 tnho-fasteners.com 配置 HTTPS。

## 方案概述

使用 Cloudflare Origin Certificate 的优势：
- ✅ **免费**：无需购买商业证书
- ✅ **有效期长**：最长 15 年
- ✅ **自动管理**：可通过 Cloudflare API 自动生成
- ✅ **高性能**：使用 ECC 证书，比 RSA 更快
- ✅ **安全性高**：仅在 Cloudflare 和源服务器之间有效

## 准备工作

### 1. 域名已添加到 Cloudflare

确保域名 `tnho-fasteners.com` 已添加到 Cloudflare，并且 DNS 解析正常。

### 2. 获取 Cloudflare API Token

#### 步骤：
1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 点击右上角头像 -> **My Profile**
3. 选择左侧菜单 **API Tokens**
4. 点击 **Create Token**

#### Token 权限配置：
创建一个自定义 Token，权限如下：

| 权限类别 | 权限类型 | 具体权限 |
|---------|---------|---------|
| Zone | Zone | Read |
| Zone | SSL and Certificates | Edit |

#### 限制范围：
- **Account**: 选择你的账户
- **Zone Resources**: Include -> Specific zone -> `tnho-fasteners.com`

#### 复制 Token：
创建完成后，**立即复制并保存** Token（只显示一次）。

### 3. 查找 Zone ID

在 Cloudflare Dashboard 中：
1. 选择域名 `tnho-fasteners.com`
2. 右侧面板可以看到 **Zone ID**
3. 复制 Zone ID

---

## 生成证书

### 方法一：使用自动脚本（推荐）

#### 1. 安装依赖
```bash
pip install requests
```

#### 2. 运行生成脚本
```bash
cd scripts
python generate_cloudflare_cert.py \
  --api-token "YOUR_API_TOKEN" \
  --domain "tnho-fasteners.com" \
  --zone-id "YOUR_ZONE_ID" \
  --output-dir "certs"
```

#### 参数说明：
- `--api-token`: Cloudflare API Token（必需）
- `--zone-id`: Cloudflare Zone ID（可选，脚本会自动查找）
- `--domain`: 域名（默认: tnho-fasteners.com）
- `--output-dir`: 输出目录（默认: certs）
- `--validity-days`: 有效期天数（默认: 5475 = 15年）

#### 输出文件：
脚本会生成以下文件：
- `certs/cloudflare-origin.pem` - 证书文件
- `certs/cloudflare-origin-key.pem` - 私钥文件
- `certs/cloudflare-origin.csr` - CSR 文件（可选）

### 方法二：手动在 Cloudflare 控制台创建

#### 步骤：
1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 选择域名 `tnho-fasteners.com`
3. 左侧菜单选择 **SSL/TLS** -> **Origin Server**
4. 点击 **Create Certificate**
5. 配置证书：
   - **Hostnames**: 输入 `tnho-fasteners.com, *.tnho-fasteners.com, www.tnho-fasteners.com`
   - **Validity**: 选择 15 年
   - **Certificate Type**: 选择 **ECDSA**（推荐，性能更好）
6. 点击 **Create**
7. **复制并保存**证书和私钥（只显示一次）

#### 保存文件：
将证书和私钥分别保存为：
- `cloudflare-origin.pem`
- `cloudflare-origin-key.pem`

---

## 部署证书到服务器

### 1. 上传证书到服务器

#### 方法一：使用 scp（本地有证书文件）
```bash
# 创建证书目录
ssh root@47.110.72.148 "mkdir -p /etc/nginx/ssl"

# 上传证书文件
scp certs/cloudflare-origin.pem root@47.110.72.148:/etc/nginx/ssl/
scp certs/cloudflare-origin-key.pem root@47.110.72.148:/etc/nginx/ssl/
```

#### 方法二：直接在服务器上创建文件
```bash
# SSH 登录服务器
ssh root@47.110.72.148

# 创建证书目录
mkdir -p /etc/nginx/ssl

# 编辑证书文件
nano /etc/nginx/ssl/cloudflare-origin.pem
# 粘贴证书内容，保存退出

# 编辑私钥文件
nano /etc/nginx/ssl/cloudflare-origin-key.pem
# 粘贴私钥内容，保存退出

# 设置私钥权限
chmod 600 /etc/nginx/ssl/cloudflare-origin-key.pem
chmod 644 /etc/nginx/ssl/cloudflare-origin.pem
```

### 2. 更新 Nginx 配置

#### 编辑 Nginx 配置文件
```bash
nano /etc/nginx/nginx.conf
```

#### 修改 SSL 证书路径（在 HTTPS server 块中）
```nginx
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Cloudflare Origin Certificate
    ssl_certificate /etc/nginx/ssl/cloudflare-origin.pem;
    ssl_certificate_key /etc/nginx/ssl/cloudflare-origin-key.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 其他配置保持不变...
}
```

#### 测试 Nginx 配置
```bash
nginx -t
```

如果显示 `syntax is ok` 和 `test is successful`，继续下一步。

#### 重载 Nginx
```bash
systemctl reload nginx
```

---

## 配置 Cloudflare DNS 和 SSL

### 1. 配置 DNS 记录

在 Cloudflare Dashboard -> DNS -> Records 中：

| 类型 | 名称 | 内容 | 代理状态 |
|------|------|------|---------|
| A | tnho-fasteners.com | 47.110.72.148 | 已代理（橙色云） |
| CNAME | www | tnho-fasteners.com | 已代理（橙色云） |

**注意**：确保代理状态为**已代理**（橙色云图标），否则 Cloudflare 不会提供保护。

### 2. 配置 SSL/TLS 加密模式

在 Cloudflare Dashboard -> SSL/TLS -> Overview 中：

选择 **加密模式**：**Full (strict)**

**说明**：
- **Full**：Cloudflare 到源服务器使用 HTTPS
- **Strict**：Cloudflare 验证源服务器证书的有效性（推荐）

### 3. 配置 Edge Certificates（可选）

在 SSL/TLS -> Edge Certificates 中：

- ✅ **Always Use HTTPS**: 启用（自动将 HTTP 重定向到 HTTPS）
- ✅ **Automatic HTTPS Rewrites**: 启用（将 HTTP 资源链接替换为 HTTPS）
- ⚠️ **HSTS**: 可选启用（建议启用后等待一段时间）

### 4. 验证 SSL 配置

在 Cloudflare Dashboard -> SSL/TLS 中，检查：
- **Overview** 显示证书状态正常
- **Edge Certificates** 显示 "Active Certificate"

---

## 测试 HTTPS 访问

### 1. 本地测试
```bash
# 测试 HTTPS 访问
curl -I https://tnho-fasteners.com

# 测试 API 端点
curl -I https://tnho-fasteners.com/health

# 查看 SSL 证书详情
curl -vI https://tnho-fasteners.com 2>&1 | grep -A 10 "SSL certificate"
```

### 2. 浏览器测试
打开浏览器访问：
- `https://tnho-fasteners.com`
- `https://www.tnho-fasteners.com`

检查：
- 地址栏显示 🔒 锁图标
- 证书由 Cloudflare 颁发（在浏览器证书详情中查看）
- HTTP 自动重定向到 HTTPS

### 3. SSL Labs 测试（可选）
访问 [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)，输入域名进行测试。

预期评分：**A+**

---

## 故障排查

### 问题 1：访问显示 "522 Connection Timed Out"

**原因**：服务器防火墙未开放端口，或 Nginx 配置错误。

**解决**：
```bash
# 检查防火墙
ufw status
ufw allow 443/tcp
ufw allow 80/tcp

# 检查 Nginx 监听端口
netstat -tlnp | grep :443

# 检查 Nginx 日志
tail -f /var/log/nginx/error.log
```

### 问题 2：显示 "520 Web Server Returned an Unknown Error"

**原因**：Nginx 配置错误或证书路径错误。

**解决**：
```bash
# 测试 Nginx 配置
nginx -t

# 检查证书文件是否存在
ls -la /etc/nginx/ssl/

# 检查证书文件权限
stat /etc/nginx/ssl/cloudflare-origin-key.pem
```

### 问题 3：浏览器显示 "Not Secure" 或证书无效

**原因**：Cloudflare SSL 加密模式配置错误。

**解决**：
- 确保 Cloudflare SSL 加密模式为 **Full (strict)**
- 确保 DNS 代理状态为**已代理**（橙色云）
- 检查 Nginx 证书路径是否正确

### 问题 4：API Token 权限不足

**错误信息**：`Authentication error`

**解决**：
- 检查 Token 是否包含 `SSL and Certificates - Edit` 权限
- 检查 Token 是否限制了 Zone
- 重新生成 Token 并确保权限正确

---

## 证书续期

### Cloudflare Origin Certificate 有效期

- 默认有效期：**15 年**（5475 天）
- 到期前需重新生成并部署

### 续期步骤

1. 重新运行证书生成脚本：
```bash
python generate_cloudflare_cert.py \
  --api-token "YOUR_API_TOKEN" \
  --domain "tnho-fasteners.com" \
  --zone-id "YOUR_ZONE_ID"
```

2. 上传新证书到服务器并替换旧文件

3. 重载 Nginx：
```bash
systemctl reload nginx
```

### 自动续期（可选）

可以创建一个定时任务，定期检查证书有效期：
```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每月 1 号检查）
0 0 1 * * /root/check_cert_expiry.sh
```

---

## 安全建议

### 1. 保护私钥
- 私钥文件权限设置为 `600`
- 不要将私钥上传到 Git 或公开仓库
- 定期轮换证书（建议每年）

### 2. 启用 HSTS
在 Nginx 配置中添加：
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### 3. 配置 Cloudflare Firewall
- 启用 Cloudflare Firewall 规则
- 阻止恶意 IP 和攻击

### 4. 监控 SSL 证书
设置监控，在证书即将到期时收到通知。

---

## 附录

### A. Nginx 完整配置示例

```nginx
# HTTP - 重定向到 HTTPS
server {
    listen 80;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Cloudflare 验证路径
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # 其他请求跳转到 HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS - 主配置
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Cloudflare Origin Certificate
    ssl_certificate /etc/nginx/ssl/cloudflare-origin.pem;
    ssl_certificate_key /etc/nginx/ssl/cloudflare-origin-key.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # 字符集
    charset utf-8;

    # API 代理
    location /api/ {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }

    # 健康检查
    location /health {
        proxy_pass http://api_backend/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # 根路径
    location / {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
```

### B. 快速检查清单

- [ ] Cloudflare API Token 已获取（SSL and Certificates - Edit 权限）
- [ ] 域名已添加到 Cloudflare
- [ ] DNS 记录已配置（A 记录指向 47.110.72.148）
- [ ] DNS 代理状态为"已代理"（橙色云）
- [ ] SSL 证书已生成并上传到服务器
- [ ] Nginx 配置已更新并重载
- [ ] Cloudflare SSL 加密模式为 Full (strict)
- [ ] Always Use HTTPS 已启用
- [ ] HTTPS 访问测试通过
- [ ] HTTP 自动重定向到 HTTPS

---

## 常见问题 FAQ

### Q1: Cloudflare Origin Certificate 可以在浏览器中直接访问吗？
**A**: 不可以。Origin Certificate 仅在 Cloudflare 和源服务器之间有效，浏览器访问时显示的是 Cloudflare Edge Certificate（由 Cloudflare 签发）。

### Q2: 可以使用 RSA 证书吗？
**A**: 可以。在生成证书时选择 **RSA** 而不是 **ECDSA**。但 ECDSA 证书性能更好，推荐使用。

### Q3: 证书到期后会自动续期吗？
**A**: 不会自动续期。需要手动重新生成并部署。

### Q4: 需要配置 Let's Encrypt 吗？
**A**: 不需要。使用 Cloudflare Origin Certificate 即可，无需 Let's Encrypt。

### Q5: 可以在多个域名上使用同一张证书吗？
**A**: 可以。生成证书时可以添加多个域名，但需要在同一 Zone 下。

---

## 联系支持

如有问题，请参考：
- [Cloudflare SSL/TLS 文档](https://developers.cloudflare.com/ssl/)
- [Nginx SSL 配置文档](https://nginx.org/en/docs/http/configuring_https_servers.html)

---

**文档版本**: 1.0
**最后更新**: 2025-01-15
