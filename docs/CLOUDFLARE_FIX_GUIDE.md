# 企业微信机器人"服务器未响应"问题解决方案

## 问题诊断

### 当前状态

✅ **服务正常运行**
- FastAPI 服务: 运行中 (PID: 1188, 端口: 8080)
- 本地访问: 正常 (`http://localhost:8080/health` 返回 `{"status":"ok"}`)
- 服务日志: 正常，无错误

❌ **域名无法访问**
- 域名访问: 超时/无响应
- Cloudflare 指向: 172.67.167.31, 104.21.42.222（Cloudflare IP）
- 服务器实际 IP: 115.190.192.22

### 问题原因

**Cloudflare 源站 IP 配置错误**

企业微信通过域名访问回调 URL 时，请求被 Cloudflare 代理，但 Cloudflare 的源站配置指向了错误的 IP 地址（可能是旧的 47.110.72.148），导致无法连接到实际的服务器（115.190.192.22）。

## 解决方案

### 方案一：更新 Cloudflare 源站 IP（推荐）

#### 步骤 1: 登录 Cloudflare 控制台

1. 访问 https://dash.cloudflare.com/
2. 输入账号密码登录
3. 在主页面选择 `tnho-fasteners.com` 域名

#### 步骤 2: 找到 DNS 记录

1. 在左侧导航栏点击 `DNS`
2. 点击 `Records` 标签页
3. 找到类型为 `A`、名称为 `@` 的记录

#### 步骤 3: 更新源站 IP

1. 点击 A 记录右侧的 `编辑` 按钮（铅笔图标）
2. 在 `Content` 字段中，将 IP 地址更新为: `115.190.192.22`
3. 确保 `Proxy status` 为 `Proxied`（橙色云朵）
4. 点击 `Save` 保存

#### 步骤 4: 验证配置

等待 5-10 分钟让 DNS 传播，然后运行以下命令验证：

```bash
# 测试健康检查接口
curl https://tnho-fasteners.com/health

# 应该返回: {"status":"ok"}

# 测试企业微信接口
curl https://tnho-fasteners.com/api/wechat/test

# 应该返回: {"status":"ok","message":"企业微信接口正常",...}
```

#### 步骤 5: 在企业微信中测试

1. 在企业微信管理后台，点击"验证"按钮
2. 如果显示"验证成功"，则配置正确
3. 在企业微信中给机器人发送测试消息

---

### 方案二：暂时使用 IP 地址（临时方案）

如果暂时无法访问 Cloudflare 控制台，可以使用 IP 地址临时配置。

#### 步骤 1: 修改企业微信回调 URL

在企业微信管理后台，将回调 URL 修改为：

```
http://47.110.72.148:8080/api/wechat/callback
```

⚠️ **注意**: 这是临时方案，不推荐长期使用，因为：
- 需要开放 8080 端口
- 安全性较低
- 无法享受 Cloudflare 的 CDN 和防护功能

#### 步骤 2: 开放服务器端口

如果使用 IP 地址，需要确保 8080 端口可以从外网访问：

```bash
# 检查防火墙状态
ufw status

# 如果防火墙未启用，启用它
ufw enable

# 允许 8080 端口
ufw allow 8080

# 或者使用 iptables
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

#### 步骤 3: 在企业微信中测试

1. 在企业微信管理后台，点击"验证"按钮
2. 如果显示"验证成功"，则配置正确
3. 在企业微信中给机器人发送测试消息

---

### 方案三：配置 Nginx 反向代理（推荐长期方案）

如果使用方案二，建议配置 Nginx 反向代理，将 80 端口的请求转发到 8080 端口。

#### 步骤 1: 安装 Nginx

```bash
apt update
apt install -y nginx
```

#### 步骤 2: 配置 Nginx

创建配置文件 `/etc/nginx/sites-available/tnho-api`:

```nginx
server {
    listen 80;
    server_name tnho-fasteners.com 47.110.72.148 115.190.192.22;

    # 文件上传大小限制
    client_max_body_size 10m;

    # 超时设置
    proxy_connect_timeout 60s;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 步骤 3: 启用配置

```bash
# 创建软链接
ln -s /etc/nginx/sites-available/tnho-api /etc/nginx/sites-enabled/

# 删除默认配置
rm /etc/nginx/sites-enabled/default

# 测试配置
nginx -t

# 重启 Nginx
systemctl restart nginx
```

#### 步骤 4: 更新企业微信回调 URL

在企业微信管理后台，将回调 URL 修改为：

```
http://tnho-fasteners.com/api/wechat/callback
```

或使用 IP 地址：

```
http://115.190.192.22/api/wechat/callback
```

---

## 验证方法

### 1. 本地测试

```bash
# 测试健康检查
curl http://localhost:8080/health

# 测试企业微信接口
curl http://localhost:8080/api/wechat/test
```

### 2. 外网测试

```bash
# 使用 IP 地址测试
curl http://115.190.192.22:8080/health

# 使用域名测试（需要 Cloudflare 配置正确）
curl https://tnho-fasteners.com/health
```

### 3. 企业微信测试

在企业微信管理后台点击"验证"按钮，查看是否显示"验证成功"。

---

## 快速检查清单

### 方案一（Cloudflare 更新）

- [ ] 登录 Cloudflare 控制台
- [ ] 找到 DNS -> Records
- [ ] 更新 A 记录的 IP 为 115.190.192.22
- [ ] 确保 Proxy status 为 Proxied（橙色云朵）
- [ ] 保存配置
- [ ] 等待 5-10 分钟
- [ ] 测试域名访问
- [ ] 在企业微信中验证

### 方案二（临时 IP）

- [ ] 修改企业微信回调 URL 为 http://47.110.72.148:8080/api/wechat/callback
- [ ] 开放 8080 端口
- [ ] 测试 IP 访问
- [ ] 在企业微信中验证

### 方案三（Nginx 反向代理）

- [ ] 安装 Nginx
- [ ] 配置 Nginx 反向代理
- [ ] 启用配置
- [ ] 重启 Nginx
- [ ] 测试反向代理
- [ ] 在企业微信中验证

---

## 故障排查

### 问题 1: Cloudflare 验证超时

**原因**: 源站 IP 配置错误或服务器不可达

**解决**:
1. 检查源站 IP 是否正确（115.190.192.22）
2. 检查服务器是否运行正常
3. 检查防火墙规则
4. 尝试使用方案二或方案三

### 问题 2: 企业微信验证失败

**原因**: Token 或 EncodingAESKey 配置错误

**解决**:
1. 检查 .env 文件中的配置是否正确
2. 确保与企业微信管理后台的配置一致
3. 重启服务: `./scripts/service.sh restart`

### 问题 3: 服务正常但无法外网访问

**原因**: 防火墙阻止或端口未开放

**解决**:
1. 检查防火墙状态: `ufw status`
2. 开放端口: `ufw allow 8080` 或 `ufw allow 80`
3. 检查安全组规则（如果使用云服务器）

### 问题 4: 端口 8080 被占用

**原因**: 其他服务占用了 8080 端口

**解决**:
1. 查看端口占用: `netstat -tuln | grep 8080`
2. 停止占用端口的服务
3. 或修改 FastAPI 服务端口

---

## 推荐方案

**长期使用**: 方案一（Cloudflare 源站 IP 更新）
- 安全性最高
- 享受 Cloudflare CDN 和防护功能
- 支持 HTTPS

**临时过渡**: 方案三（Nginx 反向代理）
- 使用 80 端口，更通用
- 可以后续配置 SSL 证书
- 比 8080 端口更安全

**快速测试**: 方案二（IP 地址）
- 配置最简单
- 适合临时测试
- 不推荐长期使用

---

## 联系支持

如果以上方案都无法解决问题，请提供以下信息：

1. 服务器 IP: 115.190.192.22
2. 服务端口: 8080
3. 域名: tnho-fasteners.com
4. 错误信息: （提供企业微信显示的错误信息）
5. 服务日志: `./scripts/service.sh logs`

---

## 更新日志

### 2025-01-14
- ✅ 诊断出问题原因：Cloudflare 源站 IP 配置错误
- ✅ 确认服务器运行正常
- ✅ 创建详细的解决方案文档
- ⚠️ 等待用户执行 Cloudflare 配置更新
