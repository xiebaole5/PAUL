# HTTPS 配置完成说明

## 当前状态

✅ HTTPS 配置已完成，服务正常运行
- HTTP (80 端口)：自动跳转到 HTTPS
- HTTPS (443 端口)：正常提供服务
- 反向代理：正常转发到 FastAPI 应用 (8080 端口)

## 当前使用的证书

目前使用的是 **自签名证书**（临时方案），可以用于测试，但浏览器会显示安全警告。

## 升级为 Cloudflare Origin Certificate（推荐）

由于 Cloudflare 正在代理请求（橙色云朵），无法直接使用 Let's Encrypt 证书。推荐使用 Cloudflare Origin Certificate。

### 步骤：

1. **登录 Cloudflare 控制台**
   - 访问 https://dash.cloudflare.com/
   - 选择 tnho-fasteners.com 域名

2. **生成 Origin Certificate**
   - 导航到 `SSL/TLS` -> `Origin Server`
   - 点击 `Create Certificate`
   - 配置：
     - Hostnames: `*.tnho-fasteners.com`, `tnho-fasteners.com`
     - Validity: 15 years
     - Certificate Type: RSA
   - 点击 `Create` 生成证书

3. **保存证书和私钥**
   - 保存 Certificate (PEM 格式) 到本地文件 `tnho-origin.crt`
   - 保存 Private Key (RSA 格式) 到本地文件 `tnho-origin.key`

4. **上传证书到服务器**
   ```bash
   scp tnho-origin.crt root@47.110.72.148:/etc/nginx/ssl/tnho-origin.crt
   scp tnho-origin.key root@47.110.72.148:/etc/nginx/ssl/tnho-origin.key
   ```

5. **重启 Nginx**
   ```bash
   nginx -t && nginx -s reload
   ```

6. **确认 Cloudflare SSL 模式**
   - 在 Cloudflare 控制台，确保 SSL/TLS 模式为 `Full` 或 `Full (strict)`
   - 不要使用 `Flexible` 模式

## 备选方案：使用 Let's Encrypt 证书

如果坚持使用 Let's Encrypt 证书，需要临时关闭 Cloudflare 代理：

1. **临时关闭 Cloudflare 代理**
   - 在 Cloudflare DNS 设置中，将 A 记录的橙色云朵改为灰色（仅 DNS）
   - 等待 DNS 传播（通常 1-5 分钟）

2. **申请证书**
   ```bash
   nginx -s stop
   certbot certonly --standalone -d tnho-fasteners.com -d www.tnho-fasteners.com --non-interactive --agree-tos --email admin@tnho-fasteners.com
   nginx
   ```

3. **更新 Nginx 配置**
   修改 `/etc/nginx/sites-available/tnho-https.conf`：
   ```nginx
   ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;
   ```

4. **重启 Cloudflare 代理**
   - 在 Cloudflare DNS 设置中，将灰色云朵改为橙色（代理开启）
   - 配置 SSL/TLS 模式为 `Full (strict)`

5. **重启 Nginx**
   ```bash
   nginx -s reload
   ```

## 测试 HTTPS 访问

### 本地测试
```bash
# 测试 HTTPS 访问（跳过证书验证）
curl -k https://localhost/health

# 测试 HTTP 到 HTTPS 跳转
curl -I http://localhost/

# 测试 API 接口
curl -k https://localhost/api/
```

### 公网测试
```bash
# 通过 IP 访问
curl -k https://47.110.72.148/health

# 通过域名访问（如果 DNS 已解析）
curl -k https://tnho-fasteners.com/health
```

### 浏览器测试
- 访问：https://tnho-fasteners.com
- 访问：https://tnho-fasteners.com/health
- 访问：https://tnho-fasteners.com/api/

**注意**：使用自签名证书时，浏览器会显示安全警告，这是正常的。

## 小程序配置

小程序已配置服务器域名：
- request 合法域名：`https://tnho-fasteners.com`
- uploadFile 合法域名：`https://tnho-fasteners.com`
- downloadFile 合法域名：`https://tnho-fasteners.com`

### 真机调试

如果遇到网络请求错误，可以在微信开发者工具中：
1. 打开 `详情` -> `本地设置`
2. 勾选 `不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书`

**注意**：正式发布时必须关闭此选项，并确保 HTTPS 证书有效。

## 服务状态检查

```bash
# 检查 Nginx 进程
ps aux | grep nginx

# 检查端口监听
netstat -tlnp | grep -E ':80 |:443 '

# 检查 FastAPI 进程
ps aux | grep python3 | grep 8080

# 查看服务日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

## 故障排查

### 问题 1：访问 https://tnho-fasteners.com 显示 502 Bad Gateway
- 检查 FastAPI 服务是否运行：`ps aux | grep 8080`
- 检查 8080 端口是否监听：`netstat -tlnp | grep 8080`

### 问题 2：浏览器显示证书无效
- 当前使用的是自签名证书，浏览器会警告
- 升级为 Cloudflare Origin Certificate 即可解决

### 问题 3：小程序无法访问
- 确认 Cloudflare 代理已开启（橙色云朵）
- 确认 SSL/TLS 模式为 `Full` 或 `Full (strict)`
- 检查小程序域名配置是否正确

### 问题 4：Nginx 配置错误
```bash
# 测试配置
nginx -t

# 查看错误日志
tail -f /var/log/nginx/error.log
```

## Nginx 配置文件位置

- HTTPS 配置：`/etc/nginx/sites-available/tnho-https.conf`
- 备份配置：`/etc/nginx/sites-available/default.backup`
- SSL 证书目录：`/etc/nginx/ssl/`

## 下一步

1. ✅ HTTPS 配置完成
2. 📋 升级为 Cloudflare Origin Certificate（推荐）
3. 📱 测试小程序 HTTPS 访问
4. 🚀 正式发布

## 技术支持

如有问题，请查看：
- Nginx 错误日志：`/var/log/nginx/error.log`
- Nginx 访问日志：`/var/log/nginx/access.log`
- FastAPI 日志：运行 `./scripts/service.sh logs`

---

**配置时间**：2026-01-14 18:30
**状态**：✅ HTTPS 已启用
**证书类型**：自签名证书（临时）
