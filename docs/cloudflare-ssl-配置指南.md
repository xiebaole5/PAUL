# Cloudflare SSL/TLS 配置指南

## 配置目标

解决当前 SSL 证书问题，使小程序能够正常访问 HTTPS API。

---

## 前提条件

- [ ] 已拥有 Cloudflare 账号
- [ ] 已将域名 `tnho-fasteners.com` 添加到 Cloudflare
- [ ] 域名已正确解析到服务器 IP：`47.110.72.148`
- [ ] 服务器 Nginx 已配置 Let's Encrypt SSL 证书

---

## 第一步：登录 Cloudflare

1. 访问 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 选择域名 `tnho-fasteners.com`
3. 进入管理面板

---

## 第二步：配置 DNS 记录

### 2.1 检查 DNS 记录

在左侧菜单点击 **DNS** → **Records**，确保有以下 A 记录：

| 类型 | 名称 | IPv4 地址 | 代理状态 | TTL |
|------|------|-----------|----------|-----|
| A | tnho-fasteners.com | 47.110.72.148 | 已代理（橙色云朵） | 自动 |
| A | www.tnho-fasteners.com | 47.110.72.148 | 已代理（橙色云朵） | 自动 |

### 2.2 修改记录（如果需要）

1. 点击记录右侧的 **编辑** 按钮
2. 确保 **代理状态** 为 **已代理**（橙色云朵图标）
3. 点击 **保存**

**注意**：
- ✅ 已代理：经过 Cloudflare CDN，访问会更快，SSL 由 Cloudflare 提供
- ❌ 仅 DNS：不经过 Cloudflare，直接访问服务器

---

## 第三步：配置 SSL/TLS 模式

### 3.1 进入 SSL/TLS 设置

在左侧菜单点击 **SSL/TLS**

### 3.2 设置加密模式

将 **加密模式**（Overview）设置为 **Full**

#### 各模式说明

| 模式 | 客户端 → Cloudflare | Cloudflare → 服务器 | 适用场景 |
|------|---------------------|---------------------|----------|
| Off | 不加密 | 不加密 | ❌ 不推荐 |
| Flexible | HTTPS | HTTP | ❌ 不推荐，Cloudflare 到服务器不安全 |
| **Full** | HTTPS | HTTPS | ✅ 推荐，不严格验证服务器证书 |
| Full (strict) | HTTPS | HTTPS | ✅ 最安全，严格验证服务器证书 |

### 3.3 推荐配置：Full 模式

选择 **Full** 模式的理由：
- 客户端到 Cloudflare 使用 HTTPS（安全）
- Cloudflare 到服务器使用 HTTPS（安全）
- 不严格验证服务器证书（避免证书链问题）

**何时使用 Full (strict) 模式**：
- 只有当你配置了完整的证书链时
- 证书中间链配置正确

---

## 第四步：配置 SSL/TLS Edge Certificates

### 4.1 启用 Always Use HTTPS

1. 点击 **Edge Certificates**
2. 开启 **Always Use HTTPS** 开关
3. 开启 **Automatic HTTPS Rewrites** 开关

### 4.2 配置 HSTS（可选，增强安全性）

1. 在 Edge Certificates 页面
2. 开启 **HSTS** 开关
3. 配置以下选项：
   - Max-Age: `6 months`（6 个月）
   - Include Subdomains: ✅ 开启
   - Preload: ✅ 开启

**注意**：开启 HSTS 后，浏览器会强制使用 HTTPS 访问，如果证书配置错误，可能导致网站无法访问。

---

## 第五步：验证配置

### 5.1 测试 HTTPS 访问

在服务器上执行：

```bash
# 测试健康检查
curl -v https://tnho-fasteners.com/health 2>&1 | grep -E "SSL|certificate|Server"

# 预期输出应包含：
# SSL certificate verify ok.
# Server: cloudflare
```

### 5.2 检查 SSL 证书

访问以下工具检查证书：
- https://www.ssllabs.com/ssltest/analyze.html?d=tnho-fasteners.com
- 或在浏览器地址栏点击锁图标查看证书信息

预期结果：
- **证书颁发者**：Let's Encrypt（服务器端） 或 Cloudflare（客户端）
- **加密强度**：A+ 或 A
- **协议**：TLS 1.2 或 TLS 1.3

### 5.3 测试小程序 API

在微信开发者工具中：
1. 修改 API 地址为：`https://tnho-fasteners.com`
2. 测试图片上传功能
3. 测试视频生成功能

---

## 第六步：小程序后台配置

### 6.1 登录微信公众平台

访问：https://mp.weixin.qq.com

### 6.2 配置服务器域名

1. 进入 **开发管理** → **开发设置** → **服务器域名**
2. 添加以下合法域名：
   - **request 合法域名**：`https://tnho-fasteners.com`
   - **uploadFile 合法域名**：`https://tnho-fasteners.com`
   - **downloadFile 合法域名**：`https://tnho-fasteners.com`

### 6.3 保存并生效

点击 **保存**，新配置通常在 10 分钟内生效。

---

## 常见问题

### Q1: Cloudflare 显示 520 Bad Gateway

**原因**：服务器应用服务未正常运行

**解决**：
```bash
# 检查应用服务
ps aux | grep python

# 检查应用是否在监听 8000 端口
sudo netstat -tlnp | grep 8000

# 如果未运行，启动应用
cd /path/to/PAUL
nohup python app.py > app.log 2>&1 &
```

### Q2: Cloudflare 显示 521 Web Server Is Down

**原因**：Nginx 未正常运行或未监听 443 端口

**解决**：
```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查 Nginx 是否监听 443 端口
sudo netstat -tlnp | grep nginx

# 如果未运行，启动 Nginx
sudo systemctl start nginx
```

### Q3: 小程序提示 "不在以下 request 合法域名列表中"

**原因**：小程序后台未配置域名或域名不匹配

**解决**：
1. 确认小程序后台已配置 `https://tnho-fasteners.com`
2. 确认小程序代码中使用的 API 地址与配置一致
3. 等待 10-15 分钟让配置生效

### Q4: 小程序提示 "request:fail 发起 request 请求失败"

**原因**：网络问题或服务器未响应

**解决**：
1. 确认服务器应用服务正在运行
2. 确认 Nginx 正在运行
3. 确认 Cloudflare SSL/TLS 模式为 Full
4. 检查服务器防火墙是否开放 443 端口

### Q5: 浏览器提示 "ERR_CERT_AUTHORITY_INVALID"

**原因**：SSL 证书配置错误或使用了自签名证书

**解决**：
1. 确认使用了 Let's Encrypt 证书
2. 确认证书未过期
3. 确认 Cloudflare SSL/TLS 模式为 Full
4. 如果使用 Full (strict)，检查证书链是否完整

---

## Cloudflare 免费套餐限制

免费套餐的 SSL/TLS 功能：
- ✅ SSL/TLS 加密（Full 模式）
- ✅ 自动 HTTPS 重定向
- ✅ HSTS 支持
- ✅ 客户端到 Cloudflare 的加密
- ✅ Cloudflare 到服务器的加密
- ✅ SSL 证书由 Cloudflare 提供（客户端侧）

**限制**：
- 不提供自定义 SSL 证书上传
- 不提供高级 WAF 功能
- 不提供 DDoS 防护增强

---

## 配置验证清单

完成配置后，请逐项验证：

### DNS 配置
- [ ] A 记录 `tnho-fasteners.com` → `47.110.72.148`（已代理）
- [ ] A 记录 `www.tnho-fasteners.com` → `47.110.72.148`（已代理）
- [ ] DNS 已生效（使用 `dig` 或 `nslookup` 检查）

### SSL/TLS 配置
- [ ] 加密模式设置为 Full
- [ ] Always Use HTTPS 已开启
- [ ] HSTS 已启用（可选）

### 服务器配置
- [ ] Let's Encrypt 证书已申请
- [ ] Nginx 配置正确且无警告
- [ ] Nginx 正在运行
- [ ] 应用服务正在运行（监听 8000 端口）

### 小程序配置
- [ ] 小程序后台已配置合法域名
- [ ] 小程序代码使用 HTTPS API 地址
- [ ] 小程序可以正常上传图片
- [ ] 小程序可以正常生成视频

### 访问测试
- [ ] `curl https://tnho-fasteners.com/health` 返回 `{"status":"ok"}`
- [ ] 浏览器访问 `https://tnho-fasteners.com` 无证书错误
- [ ] SSL Labs 测试评分 A 或 A+
- [ ] 小程序功能正常

---

## 附录：命令速查

```bash
# 测试 DNS 解析
dig tnho-fasteners.com
nslookup tnho-fasteners.com

# 测试 HTTPS 连接
curl -vI https://tnho-fasteners.com/health

# 检查 SSL 证书
openssl s_client -connect tnho-fasteners.com:443 -servername tnho-fasteners.com

# 检查端口监听
sudo netstat -tlnp | grep -E "80|443|8000"

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/tnho-fasteners-access.log
sudo tail -f /var/log/nginx/tnho-fasteners-error.log
```

---

## 相关文档

- [Cloudflare SSL/TLS 官方文档](https://developers.cloudflare.com/ssl/tls-configuration/)
- [Let's Encrypt 官方文档](https://letsencrypt.org/docs/)
- [Nginx SSL 配置指南](https://nginx.org/en/docs/http/configuring_https_servers.html)

---

## 技术支持

如果遇到问题无法解决，请提供：
1. DNS 解析结果（`dig tnho-fasteners.com`）
2. Nginx 配置文件（`cat /etc/nginx/sites-available/tnho-fasteners.com`）
3. Nginx 错误日志（`sudo tail -n 50 /var/log/nginx/error.log`）
4. curl 测试结果（`curl -v https://tnho-fasteners.com/health`）
