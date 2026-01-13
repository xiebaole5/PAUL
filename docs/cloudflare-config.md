# Cloudflare SSL/TLS配置指南

## 概述

Cloudflare作为反向代理和CDN，需要正确配置SSL/TLS模式，才能让小程序正常访问HTTPS API。

## 配置步骤

### 1. 登录Cloudflare

访问 https://dash.cloudflare.com/ 并登录

### 2. 选择域名

在域名列表中选择 `tnho-fasteners.com`

### 3. 检查DNS记录

进入 **DNS** 页面，确保有以下记录：

| 类型 | 名称 | 内容 | 代理状态 |
|------|------|------|----------|
| A | @ | 47.110.72.148 | 已代理（橙色云朵） |
| A | www | 47.110.72.148 | 已代理（橙色云朵）|

如果DNS记录未代理（灰色云朵），点击状态图标切换为橙色云朵。

### 4. 配置SSL/TLS模式

进入 **SSL/TLS** 页面，按以下步骤配置：

#### 4.1 Overview（概览）

确保显示：
- **SSL/TLS encryption mode**: Full
- **Your certificate**: Active
- **Edge Certificates**: Enabled

#### 4.2 将模式设置为 Full

在 **SSL/TLS > Overview** 页面：

**推荐配置**：
```
模式：Full
```

**各种模式说明**：

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **Off** | 不加密 | 不推荐 |
| **Flexible** | Cloudflare到服务器使用HTTP | 服务器未配置SSL时使用 |
| **Full** | Cloudflare到服务器使用HTTPS，但不验证证书 | 服务器配置自签名证书时使用 |
| **Full (strict)** | Cloudflare到服务器使用HTTPS，验证证书 | 服务器配置正式SSL证书时使用（推荐） |

**我们的配置**：
- ✅ 使用 **Full** 或 **Full (strict)**
- ✅ 服务器已配置Let's Encrypt正式证书
- ✅ 推荐：**Full (strict)**（最安全）

#### 4.3 确认Edge Certificates已启用

在 **SSL/TLS > Edge Certificates** 页面：

确保以下选项已启用：
- ✅ **Always Use HTTPS**（始终使用HTTPS）
- ✅ **Automatic HTTPS Rewrites**（自动HTTPS重写）
- ✅ **Authenticated Origin Pulls**（认证源站拉取，可选）

### 5. 配置缓存规则（可选但推荐）

进入 **Caching** 页面，配置缓存策略：

#### 5.1 Caching Level

设置为 **Standard**（标准）

#### 5.2 Browser Cache TTL

设置为 **Respect Existing Headers**（遵循现有头部）

#### 5.3 缓存规则（推荐）

创建缓存规则：

**规则1：缓存静态资源**
- 规则名称：Cache Static Assets
- 匹配条件：
  - URL Path: `/assets/*`
- 操作：
  - Cache Level: Cache Everything
  - Edge Cache TTL: 7天

**规则2：不缓存API请求**
- 规则名称：Bypass API Cache
- 匹配条件：
  - URL Path: `/api/*`
- 操作：
  - Cache Level: Bypass

### 6. 配置Page Rules（可选）

如果需要更精细的控制，可以创建Page Rules：

**规则1：强制HTTPS**
- URL: `http://tnho-fasteners.com/*`
- 操作：Always Use HTTPS

**规则2：禁用API缓存**
- URL: `https://tnho-fasteners.com/api/*`
- 操作：Disable Performance

### 7. 配置安全设置（推荐）

进入 **Security** 页面：

#### 7.1 Firewall Rules

创建防火墙规则，防止滥用：

**规则1：限制请求频率**
- 规则名称：Rate Limit API Requests
- 匹配条件：
  - URI Path: `/api/*`
- 操作：
  - Rate Limiting: 100 requests per minute

**规则2：阻止恶意请求**
- 规则名称：Block Malicious Requests
- 匹配条件：
  - URI Path: `/api/*`
  - Attack Score: High
- 操作：Block

#### 7.2 Bot Fight Mode

开启 **Bot Fight Mode**，防止机器人攻击。

### 8. 验证配置

#### 8.1 检查SSL/TLS状态

在Cloudflare中查看SSL/TLS状态是否为 **Active**

#### 8.2 测试HTTPS访问

```bash
# 测试直接访问服务器
curl -I https://47.110.72.148/health

# 测试通过Cloudflare访问
curl -I https://tnho-fasteners.com/health

# 检查证书信息
curl -vI https://tnho-fasteners.com/health 2>&1 | grep -i ssl
```

#### 8.3 检查证书链

访问 https://www.ssllabs.com/ssltest/analyze.html?d=tnho-fasteners.com

应该看到：
- Grade: A 或 A+
- Certificate: Valid
- Chain: Complete

### 9. 常见问题排查

#### 问题1：访问HTTPS时显示"您的连接不是私密连接"

**可能原因**：
- 服务器SSL证书未正确配置
- Cloudflare模式设置错误

**解决方法**：
1. 检查Nginx配置中的证书路径
2. 确认Cloudflare SSL/TLS模式为 Full
3. 测试直接访问服务器：`curl -I https://47.110.72.148/health`

#### 问题2：小程序无法连接服务器

**可能原因**：
- Cloudflare模式为 Flexible
- 服务器未配置SSL
- 小程序未配置合法域名

**解决方法**：
1. 将Cloudflare模式改为 Full
2. 确认服务器Nginx已配置SSL证书
3. 在小程序后台添加合法域名

#### 问题3：502 Bad Gateway

**可能原因**：
- 服务器应用未运行
- Nginx配置错误
- 防火墙阻止连接

**解决方法**：
```bash
# 检查服务器应用是否运行
ps aux | grep "python app.py"

# 检查Nginx配置
sudo nginx -t

# 检查Nginx错误日志
sudo tail -f /var/log/nginx/error.log

# 重启应用
cd /app
python app.py
```

#### 问题4：522 Connection Timed Out

**可能原因**：
- 服务器防火墙阻止连接
- Cloudflare无法连接到服务器

**解决方法**：
```bash
# 检查防火墙规则
sudo iptables -L -n | grep 443

# 开放443端口
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 检查服务器监听端口
netstat -tlnp | grep 443
```

### 10. 性能优化建议

#### 10.1 启用HTTP/3

在 **Network** 页面启用 HTTP/3，提升性能。

#### 10.2 配置Brotli压缩

在 **Speed > Optimization** 页面启用 Brotli 压缩。

#### 10.3 配置Rocket Loader

在 **Speed > Optimization** 页面启用 Rocket Loader，优化JavaScript加载。

#### 10.4 配置Auto Minify

在 **Speed > Optimization** 页面启用：
- Auto Minify CSS
- Auto Minify JavaScript
- Auto Minify HTML

### 11. 监控和分析

使用Cloudflare Analytics监控：

- **Traffic**: 流量统计
- **Requests**: 请求统计
- **Bandwidth**: 带宽使用
- **Threats**: 威胁防护
- **Firewall**: 防火墙日志

### 12. 配置清单

完成以下配置后，Cloudflare配置完成：

- [ ] DNS记录已配置并代理（橙色云朵）
- [ ] SSL/TLS模式设置为 Full
- [ ] Edge Certificates已启用
- [ ] Always Use HTTPS已开启
- [ ] 缓存规则已配置
- [ ] 安全规则已配置
- [ ] HTTPS访问正常
- [ ] 小程序可以正常连接服务器

## 最佳实践

1. **使用Full (strict)模式**：最安全的配置，验证服务器证书
2. **启用Always Use HTTPS**：强制所有流量使用HTTPS
3. **配置缓存规则**：提升静态资源加载速度
4. **设置安全规则**：防止滥用和攻击
5. **定期监控**：查看Analytics，及时发现异常
6. **备份配置**：定期导出Cloudflare配置备份

## 联系支持

如果遇到问题：

1. 查看Cloudflare文档：https://developers.cloudflare.com/
2. 查看Cloudflare社区：https://community.cloudflare.com/
3. 联系Cloudflare支持（付费计划）

---

**配置完成后，记得更新小程序API地址并配置小程序后台域名！**
