# 企业微信 URL 验证问题诊断报告

## 网络拓扑
```
企业微信 → Cloudflare CDN (104.21.42.222, 172.67.167.31) → 源站服务器
```

## 问题分析

### 1. 域名解析
- **域名**: tnho-fasteners.com
- **DNS 解析**: Cloudflare CDN IP (104.21.42.222, 172.67.167.31)
- **返回错误**: 522 (Cloudflare 无法连接到源站)

### 2. 源站服务器信息
- **内网 IP**: 9.128.84.91
- **公网 IP**: 115.191.1.219
- **负载均衡器 IP**: 47.110.72.148（已废弃，返回 Nginx 响应）
- **FastAPI 服务端口**: 8080

### 3. 服务状态
✅ FastAPI 服务正常运行（PID: 2062）
✅ 监听 0.0.0.0:8080
✅ 内网访问正常: http://9.128.84.91:8080/health
✅ 企业微信接口正常: http://9.128.84.91:8080/api/wechat/test

### 4. Cloudflare 错误 522
**原因**: Cloudflare 无法连接到源站服务器

**可能原因**:
1. Cloudflare 源站地址配置错误
2. Cloudflare 源站端口配置错误（可能配置为 80/443，但源站是 8080）
3. 防火墙阻止 Cloudflare IP 连接
4. 源站服务器只监听 0.0.0.0:8080，但 Cloudflare 尝试连接 80/443

## 解决方案

### 方案 1: 修复 Cloudflare 配置（推荐）

**步骤**:
1. 登录 Cloudflare 控制台
2. 选择 tnho-fasteners.com 域名
3. 进入 DNS 设置 → Proxy 状态
4. 修改源站地址为: `115.191.1.219`
5. 修改源站端口为: `8080`（如果 Cloudflare 支持）

**限制**: Cloudflare 免费版可能不支持自定义端口

### 方案 2: 配置 FastAPI 监听 80/443 端口

**步骤**:
1. 停止当前服务
2. 让 FastAPI 监听 80 端口（HTTP）
3. 配置 HTTPS 证书监听 443 端口

**问题**: 80 端口可能被其他服务占用或拦截

### 方案 3: 使用 HTTP + 自定义端口（如果企业微信支持）

**验证配置**:
```
URL: http://115.191.1.219:8080/api/wechat/callback
Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
```

**限制**: 企业微信可能不支持自定义端口或 HTTP 协议

### 方案 4: 使用端口转发

**步骤**:
1. 创建端口转发服务，将 80 端口转发到 8080
2. 使用域名访问

**问题**: 80 端口可能被负载均衡器拦截

## 当前环境变量配置

```env
WECHAT_CORP_ID=ww4564cfcc6de70e6c
WECHAT_TOKEN=gkIzrwgJI041s52TPAszz2j5iGnpZ4
WECHAT_ENCODING_AES_KEY=2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
WECHAT_CALLBACK_URL=https://tnho-fasteners.com/api/wechat/callback
```

## 建议操作顺序

1. **尝试方案 3**: 使用真实公网 IP + HTTP + 自定义端口
2. **如果失败**: 修复 Cloudflare 配置（方案 1）
3. **如果仍失败**: 配置端口转发或 HTTPS（方案 2/4）

## 调试命令

```bash
# 测试内网访问
curl http://9.128.84.91:8080/api/wechat/test

# 测试公网 IP 访问
curl http://115.191.1.219:8080/api/wechat/test

# 测试域名访问
curl http://tnho-fasteners.com/api/wechat/test
curl https://tnho-fasteners.com/api/wechat/test

# 检查服务状态
ps aux | grep "python3 app.py"
netstat -tlnp | grep 8080
```

## 备注

- 企业微信要求回调 URL 必须是 HTTPS 安全域名
- Cloudflare SSL/TLS 模式当前为 Flexible（仅加密 Cloudflare 到用户）
- 需要配置 Cloudflare 正确连接到源站服务器
