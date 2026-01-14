# Cloudflare Origin Certificate 部署指南

## 🎯 目标

升级为 Cloudflare Origin Certificate，解决小程序 HTTPS 访问问题。

## 📋 前置要求

1. **Cloudflare 账号**
   - 域名已托管在 Cloudflare
   - 域名：tnho-fasteners.com

2. **服务器访问权限**
   - SSH 访问权限（root 用户）
   - 服务器 IP：47.110.72.148

3. **本地环境**
   - Python 3.7+
   - pip 包管理器
   - SSH 客户端

---

## 🔧 方案一：使用 Python 脚本自动生成和部署（推荐）

### 步骤 1：获取 Cloudflare API Token

1. **登录 Cloudflare 控制台**
   - 访问：https://dash.cloudflare.com/
   - 使用 Cloudflare 账号登录

2. **创建 API Token**
   - 点击右上角头像 -> `My Profile`
   - 选择 `API Tokens` 标签
   - 点击 `Create Token`
   - 选择 `Edit zone DNS` 模板（或自定义）
   - 配置权限：
     - `Zone` -> `SSL and Certificates` -> `Edit`
     - `Zone Resources` -> `Include` -> `Specific zone` -> `tnho-fasteners.com`
   - 点击 `Continue to summary`
   - 点击 `Create Token`
   - **复制保存 Token**（只显示一次）

### 步骤 2：安装依赖

```bash
pip install requests
```

### 步骤 3：生成证书

在项目根目录执行：

```bash
python scripts/generate_cloudflare_cert.py \
  --api-token YOUR_API_TOKEN \
  --domain tnho-fasteners.com
```

参数说明：
- `--api-token`：Cloudflare API Token（必需）
- `--domain`：域名（默认：tnho-fasteners.com）
- `--validity-days`：证书有效期（天，默认：5475 天 = 15 年）
- `--output-dir`：输出目录（默认：certs）

**输出**：
- `certs/cloudflare-origin.crt`：证书文件
- `certs/cloudflare-origin.key`：私钥文件

### 步骤 4：部署证书

```bash
chmod +x scripts/deploy_cloudflare_cert.sh
./scripts/deploy_cloudflare_cert.sh \
  --cert certs/cloudflare-origin.crt \
  --key certs/cloudflare-origin.key
```

参数说明：
- `--cert`：证书文件路径（必需）
- `--key`：私钥文件路径（必需）
- `--server`：服务器 IP（默认：47.110.72.148）
- `--user`：SSH 用户名（默认：root）
- `--port`：SSH 端口（默认：22）
- `--dry-run`：仅显示命令，不实际执行

**示例**：
```bash
# 使用默认配置
./scripts/deploy_cloudflare_cert.sh \
  --cert certs/cloudflare-origin.crt \
  --key certs/cloudflare-origin.key

# 指定服务器 IP
./scripts/deploy_cloudflare_cert.sh \
  --cert certs/cloudflare-origin.crt \
  --key certs/cloudflare-origin.key \
  --server 47.110.72.148

# 仅测试，不实际执行
./scripts/deploy_cloudflare_cert.sh \
  --cert certs/cloudflare-origin.crt \
  --key certs/cloudflare-origin.key \
  --dry-run
```

### 步骤 5：验证部署

```bash
# 测试 HTTPS 访问
curl -I https://tnho-fasteners.com

# 测试健康检查接口
curl https://tnho-fasteners.com/health
```

预期结果：
- 返回状态码 200
- 无证书错误警告

### 步骤 6：配置 Cloudflare SSL

1. **登录 Cloudflare 控制台**
   - 访问：https://dash.cloudflare.com/
   - 选择 `tnho-fasteners.com` 域名

2. **配置 SSL/TLS**
   - 导航到 `SSL/TLS` -> `Overview`
   - 选择模式：`Full` 或 `Full (strict)`
   - **不要**使用 `Flexible` 模式

3. **确认 DNS 设置**
   - 导航到 `DNS` -> `Records`
   - 确保 A 记录的代理状态为 `Proxied`（橙色云朵）
   - 目标 IP：47.110.72.148

### 步骤 7：测试小程序

1. **打开微信开发者工具**
2. **刷新小程序**
3. **测试 API 调用**
   - 应该可以正常访问 API
   - 不再出现证书错误

---

## 🔧 方案二：手动生成证书（备选）

### 步骤 1：在 Cloudflare 控制台生成证书

1. **登录 Cloudflare 控制台**
   - 访问：https://dash.cloudflare.com/

2. **生成 Origin Certificate**
   - 选择 `tnho-fasteners.com` 域名
   - 导航到 `SSL/TLS` -> `Origin Server`
   - 点击 `Create Certificate`
   - 配置：
     - **Hostnames**: `*.tnho-fasteners.com`, `tnho-fasteners.com`
     - **Validity**: 15 years
     - **Certificate Type**: RSA
   - 点击 `Create`

3. **保存证书和私钥**
   - 复制 Certificate (PEM 格式) 内容
   - 保存为本地文件：`tnho-origin.crt`
   - 复制 Private Key (RSA 格式) 内容
   - 保存为本地文件：`tnho-origin.key`

### 步骤 2：上传证书到服务器

```bash
# 上传证书
scp tnho-origin.crt root@47.110.72.148:/etc/nginx/ssl/tnho-origin.crt

# 上传私钥
scp tnho-origin.key root@47.110.72.148:/etc/nginx/ssl/tnho-origin.key
```

### 步骤 3：设置证书权限

SSH 登录服务器后执行：

```bash
# 设置证书权限
chmod 644 /etc/nginx/ssl/tnho-origin.crt
chmod 600 /etc/nginx/ssl/tnho-origin.key
```

### 步骤 4：测试 Nginx 配置

```bash
nginx -t
```

预期输出：
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 步骤 5：重启 Nginx

```bash
nginx -s reload
```

### 步骤 6：验证部署

```bash
# 检查证书信息
openssl x509 -in /etc/nginx/ssl/tnho-origin.crt -noout -subject -issuer -dates

# 测试 HTTPS 访问
curl -I https://localhost

# 测试健康检查
curl -k https://localhost/health
```

### 步骤 7：配置 Cloudflare SSL

同方案一步骤 6

---

## ✅ 验证清单

部署完成后，请按以下清单验证：

### 服务器端

- [ ] Nginx 配置测试通过：`nginx -t`
- [ ] Nginx 服务正常运行：`ps aux | grep nginx`
- [ ] 证书文件存在：`ls -la /etc/nginx/ssl/`
- [ ] 证书权限正确：
  - 证书：`chmod 644 /etc/nginx/ssl/tnho-origin.crt`
  - 私钥：`chmod 600 /etc/nginx/ssl/tnho-origin.key`
- [ ] HTTPS 端口监听：`netstat -tlnp | grep :443`
- [ ] 本地访问测试：`curl -k https://localhost/health`

### Cloudflare 端

- [ ] SSL/TLS 模式为 `Full` 或 `Full (strict)`
- [ ] DNS 记录为 `Proxied`（橙色云朵）
- [ ] A 记录指向 47.110.72.148

### 公网访问

- [ ] 浏览器访问：https://tnho-fasteners.com
- [ ] 健康检查接口：https://tnho-fasteners.com/health
- [ ] 无证书警告

### 小程序端

- [ ] API 地址配置：`https://tnho-fasteners.com`
- [ ] 微信开发者工具可以正常打开小程序
- [ ] API 调用成功（无证书错误）
- [ ] 真机调试可以正常访问（如启用）

---

## 🆘 常见问题

### 问题 1：API Token 无权限

**错误**：
```
{"success":false,"errors":[{"code":10000,"message":"Authentication error"}]}
```

**解决方案**：
- 确认 API Token 权限包含 `SSL and Certificates` -> `Edit`
- 确认 API Token 对应正确的域名（tnho-fasteners.com）

---

### 问题 2：证书上传失败

**错误**：
```
Permission denied (publickey,password)
```

**解决方案**：
- 确认 SSH 密钥已配置
- 或使用密码认证：`ssh-copy-id root@47.110.72.148`
- 检查 SSH 端口是否正确

---

### 问题 3：Nginx 配置测试失败

**错误**：
```
nginx: [emerg] SSL_CTX_use_PrivateKey_file(...) failed
```

**解决方案**：
- 确认私钥文件完整且未损坏
- 确认私钥文件权限为 600
- 确认证书和私钥匹配

---

### 问题 4：浏览器仍显示证书警告

**可能原因**：
- Cloudflare SSL 模式配置错误
- DNS 未生效

**解决方案**：
1. 确认 SSL/TLS 模式为 `Full` 或 `Full (strict)`
2. 清除浏览器缓存和 DNS 缓存
3. 使用隐身模式访问

---

### 问题 5：小程序仍无法访问

**可能原因**：
- 小程序缓存未清除
- API 地址配置错误

**解决方案**：
1. 在微信开发者工具中：
   - 点击 `清缓存` -> `清除全部缓存`
   - 点击 `编译`
2. 检查 `miniprogram/app.js` 中的 `apiUrl` 配置：
   ```javascript
   apiUrl: 'https://tnho-fasteners.com',
   ```
3. 如果仍无法访问，尝试临时关闭域名校验

---

## 🔄 回滚方案

如果部署失败，可以回滚到之前的配置：

```bash
# SSH 登录服务器
ssh root@47.110.72.148

# 查找备份文件
ls -la /etc/nginx/ssl/*.backup.*

# 恢复备份
cp /etc/nginx/ssl/tnho-origin.crt.backup.* /etc/nginx/ssl/tnho-origin.crt
cp /etc/nginx/ssl/tnho-origin.key.backup.* /etc/nginx/ssl/tnho-origin.key

# 重启 Nginx
nginx -t && nginx -s reload
```

---

## 📚 相关文档

- [HTTPS 配置完成说明](HTTPS_SETUP.md)
- [小程序问题排查指南](../miniprogram/小程序问题排查指南.md)
- [Cloudflare SSL 官方文档](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/)

---

## 💬 需要帮助？

如果遇到问题，请提供以下信息：

1. **错误信息**：完整的错误日志
2. **执行步骤**：具体的操作步骤
3. **环境信息**：
   - 操作系统版本
   - Python 版本
   - Nginx 版本
4. **配置文件**：相关配置文件内容（隐去敏感信息）

---

**更新时间**：2026-01-14 18:40
**版本**：v1.0.0
