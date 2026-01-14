# Cloudflare 安全规则修复指南

## 问题描述

小程序在调用 API 时返回 **403 Forbidden** 错误：

```
tnho-fasteners.com/api/generate-video:1 Failed to load resource: the server responded with a status of 403 ()
tnho-fasteners.com/api/upload-image:1 Failed to load resource: the server responded with a status of 403 ()
```

## 根本原因

**Cloudflare Bot Fight Mode** 误判小程序的 API 请求为机器人/爬虫流量，导致自动拦截。

### 为什么会出现这个问题？

1. **小程序请求特征**：微信小程序的网络请求具有某些特殊的 User-Agent 或行为模式
2. **Bot Fight Mode 激进拦截**：Cloudflare 的 Bot Fight Mode 使用 JavaScript 检测技术来识别机器人
3. **小程序不支持 JS 挑战**：小程序无法响应 Cloudflare 的 JS 质询，导致被拦截

### 为什么关闭域名校验也不行？

- 关闭域名校验只是跳过了微信小程序的域名白名单验证
- 但请求仍然经过 Cloudflare CDN 代理
- Bot Fight Mode 在 Cloudflare 边缘节点拦截请求，**发生在请求到达服务器之前**
- 因此，即使关闭域名校验，仍然会被 Cloudflare 拦截

## 解决方案

### 方案一：关闭 Bot Fight Mode（推荐）⭐

这是最简单、最直接的解决方案。

#### 手动配置步骤：

1. 登录 [Cloudflare 控制台](https://dash.cloudflare.com/)
2. 选择你的域名：**tnho-fasteners.com**
3. 左侧菜单点击：**Security（安全）**
4. 点击 **Settings（设置）**
5. 找到 **Bot fight mode** 部分
6. 将 **JS Detections** 设置为：**Off（关闭）**
7. 保存设置

#### 自动化配置（推荐）：

```bash
# 设置 Cloudflare API 凭证
export CLOUDFLARE_API_TOKEN="your_api_token_here"
export CLOUDFLARE_ZONE_ID="your_zone_id_here"
export CLOUDFLARE_ACCOUNT_ID="your_account_id_here"

# 运行修复脚本
python3 scripts/fix_cloudflare_security.py

# 选择选项 1：关闭 Bot Fight Mode
```

#### 获取 API Token 和 Zone ID：

1. **API Token**：
   - 访问：https://dash.cloudflare.com/profile/api-tokens
   - 点击 "Create Token"
   - 选择模板：Edit zone DNS
   - 或者自定义权限：Zone - Zone Settings - Edit
   - 设置资源：Include - Specific zone - tnho-fasteners.com
   - 创建并复制 Token

2. **Zone ID**：
   - 访问：https://dash.cloudflare.com/
   - 选择 tnho-fasteners.com 域名
   - 在右侧边栏找到 "API" 部分
   - 复制 Zone ID

### 方案二：创建 IP Access Rules（白名单）

创建规则允许所有流量通过，绕过 Bot Fight Mode。

#### 手动配置步骤：

1. 在 Cloudflare 控制台，点击：**Security -> WAF -> IP Access Rules**
2. 点击：**Create IP access custom rule**
3. 配置规则：
   - **Field**: IP Address
   - **Operator**: is in
   - **Value**: `0.0.0.0/0` （允许所有 IP）
   - **Action**: Allow（白名单）
4. 点击：**Save and Deploy**

#### 自动化配置：

```bash
python3 scripts/fix_cloudflare_security.py
# 选择选项 2
```

### 方案三：创建 Zone Lockdown 规则（仅保护 API 路径）

更精细的控制，只对 API 路径创建白名单规则。

#### 手动配置步骤：

1. 在 Cloudflare 控制台，点击：**Security -> WAF -> Zone Lockdown**
2. 点击：**Create Zone Lockdown custom rule**
3. 配置规则：
   - **URL pattern**: `https://tnho-fasteners.com/api/*`
   - **Add IP address**: `0.0.0.0/0`
   - **Action**: Allow
4. 点击：**Save and Deploy**

#### 自动化配置：

```bash
python3 scripts/fix_cloudflare_security.py
# 选择选项 3
```

### 方案四：调整安全级别（不推荐）

将安全级别降低为 "Essentially Off"。

**缺点**：会降低整体安全性，可能允许真正的恶意流量通过。

## 配置后验证

### 1. 清除缓存

在微信开发者工具中：
1. 点击 **工具（菜单）-> 清缓存 -> 清除全部缓存**
2. 或者：**详情 -> 本地设置 -> 清除缓存**

### 2. 重新编译

1. 点击 **编译（Build）** 按钮
2. 等待小程序重新加载

### 3. 测试功能

1. 点击 **图片上传** 按钮
2. 选择一张图片
3. 查看控制台，应该不再出现 403 错误
4. 如果仍然失败，尝试：

#### 方案 A：临时绕过 Cloudflare（仅测试用）

修改小程序 API 地址，直接访问服务器 IP：

```javascript
// app.js 或 pages/index/index.js
// 将 API 地址改为服务器的 IP 地址
const apiUrl = 'http://47.110.72.148:8080'; // 临时用于测试
```

**注意**：这种方式仅用于测试，不能用于生产环境！

#### 方案 B：检查 Nginx 日志

```bash
# 查看 Nginx 访问日志
sudo tail -f /var/log/nginx/access.log

# 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

### 4. 使用 curl 测试

在服务器上测试 API 是否正常：

```bash
# 测试健康检查接口
curl -I https://tnho-fasteners.com/health

# 测试图片上传接口
curl -I https://tnho-fasteners.com/api/upload-image
```

如果返回 `200 OK`，说明服务器正常，问题确实在 Cloudflare。

## 小程序端配置（正式环境）

### 1. 配置服务器域名

登录 [微信小程序后台](https://mp.weixin.qq.com/)：

1. 进入 **开发 -> 开发管理 -> 开发设置**
2. 找到 **服务器域名**
3. 配置以下合法域名：
   - **request 合法域名**: `https://tnho-fasteners.com`
   - **uploadFile 合法域名**: `https://tnho-fasteners.com`
   - **downloadFile 合法域名**: `https://tnho-fasteners.com`

### 2. 修改小程序 API 地址

确保小程序使用 HTTPS 域名：

```javascript
// app.js
App({
  globalData: {
    apiUrl: 'https://tnho-fasteners.com'  // 确保是 HTTPS
  }
})
```

```javascript
// pages/index/index.js
const app = getApp()
const apiUrl = app.globalData.apiUrl || 'https://tnho-fasteners.com'
```

### 3. 调整超时时间

确保网络请求超时时间足够长：

```javascript
// pages/index/index.js
wx.request({
  url: `${apiUrl}/api/generate-video`,
  method: 'POST',
  data: {...},
  timeout: 30000,  // 30秒超时
  success: (res) => {...},
  fail: (err) => {...}
})
```

## 常见问题

### Q1: 配置后仍然 403 怎么办？

**A**: 尝试以下步骤：

1. 清除 Cloudflare 缓存：
   - Cloudflare 控制台 -> Caching -> Configuration -> Purge Everything
2. 等待 5-10 分钟让配置生效
3. 在微信开发者工具中清除缓存并重新编译
4. 如果仍然失败，尝试临时关闭域名校验测试

### Q2: 关闭 Bot Fight Mode 安全吗？

**A**: 有一定风险，但可以接受：

- **风险**：可能无法拦截简单的机器人流量
- **缓解措施**：
  - 启用 WAF 规则和 Managed Ruleset
  - 启用 Firewall Rules
  - 启用 Rate Limiting（速率限制）
  - 使用 Turnstile（人机验证）保护敏感接口

### Q3: 为什么不直接绕过 Cloudflare？

**A**: Cloudflare 提供了以下好处：

- CDN 加速（全球节点缓存）
- DDoS 防护
- SSL/TLS 加密
- Web Application Firewall（WAF）
- 流量分析和安全报告

### Q4: 可以同时使用多个方案吗？

**A**: 可以，但建议：

- **优先使用方案一**（关闭 Bot Fight Mode）
- 如果担心安全，可以同时使用 **方案三**（Zone Lockdown）
- 方案二（IP Access Rules）比较激进，不建议在生产环境使用

## 安全最佳实践

在修复 403 问题的同时，保持网站安全：

### 1. 启用 Managed Ruleset

- Cloudflare 控制台 -> Security -> WAF -> Managed rules
- 启用 Cloudflare Managed Ruleset

### 2. 启用 Rate Limiting

- 防止 API 滥用
- 设置每分钟/每小时的最大请求数

### 3. 使用 Turnstile（可选）

- 在关键操作（如视频生成）前添加人机验证
- 替代传统的 CAPTCHA，用户体验更好

### 4. 监控流量和日志

- 定期查看 Cloudflare Analytics
- 监控异常流量模式

## 快速参考

### 常用 Cloudflare API 端点

```bash
# 获取 Zone 信息
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer YOUR_API_TOKEN"

# 获取 Zone ID
curl -X GET "https://api.cloudflare.com/client/v4/zones?name=tnho-fasteners.com" \
  -H "Authorization: Bearer YOUR_API_TOKEN"

# 查看当前 Bot Fight Mode 设置
curl -X GET "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/settings/bot_fight_mode" \
  -H "Authorization: Bearer YOUR_API_TOKEN"

# 关闭 Bot Fight Mode
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/settings/bot_fight_mode" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"value":"off"}'
```

### Nginx 日志查看

```bash
# 实时查看访问日志
sudo tail -f /var/log/nginx/access.log

# 查看最近的 403 错误
sudo grep " 403 " /var/log/nginx/access.log | tail -20

# 查看 Cloudflare IP 访问记录
sudo grep "Cloudflare" /var/log/nginx/access.log | tail -20
```

## 总结

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| 关闭 Bot Fight Mode | 简单快速 | 安全性略降 | ⭐⭐⭐⭐⭐ |
| IP Access Rules | 彻底解决 | 太激进，不安全 | ⭐⭐ |
| Zone Lockdown | 精细控制 | 仅保护 API 路径 | ⭐⭐⭐⭐ |
| 降低安全级别 | 简单 | 太危险 | ⭐ |

**推荐做法**：关闭 Bot Fight Mode + 启用 Managed Ruleset + Rate Limiting

---

**文档版本**: 1.0
**最后更新**: 2025-01-XX
**适用域名**: tnho-fasteners.com
