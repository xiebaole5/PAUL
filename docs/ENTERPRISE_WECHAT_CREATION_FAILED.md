# 企业微信机器人创建失败解决方案

## 问题诊断

### 当前状态

从测试结果来看：

```bash
$ curl https://tnho-fasteners.com/api/wechat/callback?echostr=test
error code: 522

$ curl https://tnho-fasteners.com/health
error code: 522
```

**522 错误**: Cloudflare 无法连接到源站服务器

### 问题原因

1. **Nginx 配置问题**: 之前配置 Nginx 时出现冲突和启动失败
2. **Nginx 服务未运行**: Nginx 可能已经停止
3. **80 端口无法访问**: Cloudflare 无法通过 80 端口连接到服务器

企业微信创建机器人时会验证回调 URL，如果无法连接到服务器，就会创建失败。

---

## 解决方案

### 方案一：修复 Nginx 配置（推荐）⭐

#### 步骤 1: 检查 Nginx 状态

在服务器上执行：

```bash
# 检查 Nginx 状态
systemctl status nginx

# 查看 Nginx 错误日志
journalctl -xeu nginx.service
```

#### 步骤 2: 如果 Nginx 未运行，启动并配置

```bash
# 1. 备份现有配置
cp -r /etc/nginx /etc/nginx.backup.$(date +%Y%m%d_%H%M%S)

# 2. 停止 Nginx
systemctl stop nginx

# 3. 删除所有配置文件
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/conf.d/*.conf
rm -f /etc/nginx/sites-available/*

# 4. 创建新的配置文件
cat > /etc/nginx/conf.d/tnho-api.conf << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com 115.190.192.22;

    client_max_body_size 10m;
    proxy_connect_timeout 60s;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;

    access_log /var/log/nginx/tnho-access.log;
    error_log /var/log/nginx/tnho-error.log;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 5. 测试配置
nginx -t

# 6. 启动 Nginx
systemctl start nginx

# 7. 检查 Nginx 状态
systemctl status nginx
```

#### 步骤 3: 验证配置

```bash
# 测试健康检查接口
curl https://tnho-fasteners.com/health

# 应该返回: {"status":"ok"}

# 测试企业微信接口
curl https://tnho-fasteners.com/api/wechat/test

# 应该返回: {"status":"ok","message":"企业微信接口正常",...}
```

#### 步骤 4: 重新创建企业微信机器人

1. 刷新企业微信管理后台页面
2. 重新填写机器人信息：
   - 名称：TNHO 全能营销助手
   - 简介一键生成产品宣传视频、图片、文案和语音，支持多种营销场景
   - URL：https://tnho-fasteners.com/api/wechat/callback
   - Token：gkIzrwgJI041s52TPAszz2j5iGnpZ4
   - EncodingAESKey：2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
3. 点击"创建"

---

### 方案二：使用 IP 地址临时配置（快速测试）⚡

如果无法立即修复 Nginx，可以使用 IP 地址临时配置：

#### 步骤 1: 检查 FastAPI 服务

```bash
cd /workspace/projects
./scripts/service.sh status
```

如果服务未运行，启动服务：
```bash
./scripts/service.sh restart
```

#### 步骤 2: 检查 8080 端口是否可访问

从外部服务器测试：
```bash
curl http://115.190.192.22:8080/health
```

如果可以访问，继续下一步；如果无法访问，说明防火墙或安全组阻止了 8080 端口。

#### 步骤 3: 开放 8080 端口（如果需要）

```bash
# 使用 iptables 开放端口
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# 或使用 firewall-cmd（如果使用 firewalld）
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# 或使用 ufw（如果使用 ufw）
ufw allow 8080/tcp
```

#### 步骤 4: 使用 IP 地址创建机器人

在企业微信管理后台，填写：

- URL：http://115.190.192.22:8080/api/wechat/callback
- Token：gkIzrwgJI041s52TPAszz2j5iGnpZ4
- EncodingAESKey：2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr

⚠️ **注意**: 这是临时方案，不推荐长期使用

---

### 方案三：使用简单的 HTTP 服务器（最简单）🔧

如果 Nginx 和 8080 端口都有问题，可以使用简单的 HTTP 服务器：

#### 步骤 1: 创建简单的 Python HTTP 代理

```bash
cd /workspace/projects

# 创建代理脚本
cat > proxy_server.py << 'EOF'
import http.server
import socketserver
import urllib.parse
from urllib.request import urlopen, Request

PORT = 80

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.proxy_request("GET")

    def do_POST(self):
        self.proxy_request("POST")

    def proxy_request(self, method):
        try:
            # 构建目标 URL
            target_url = f"http://localhost:8080{self.path}"
            if self.query:
                target_url += f"?{self.query}"

            # 转发请求
            headers = {k: v for k, v in self.headers.items() if k.lower() != 'host'}
            headers['Host'] = 'tnho-fasteners.com'

            req = Request(target_url, headers=headers)
            req.get_method = lambda: method

            with urlopen(req, timeout=30) as response:
                content = response.read()

                # 返回响应
                self.send_response(response.status)
                for k, v in response.headers.items():
                    if k.lower() not in ['transfer-encoding', 'connection']:
                        self.send_header(k, v)
                self.end_headers()
                self.wfile.write(content)

        except Exception as e:
            self.send_error(502, f"Proxy Error: {str(e)}")

with socketserver.TCPServer(("", PORT), ProxyHandler) as httpd:
    print(f"Proxy server running on port {PORT}")
    httpd.serve_forever()
EOF

# 运行代理服务器
nohup python3 proxy_server.py > proxy.log 2>&1 &
```

#### 步骤 2: 验证代理服务器

```bash
# 测试健康检查
curl http://localhost/health

# 从外部测试
curl https://tnho-fasteners.com/health
```

#### 步骤 3: 在企业微信中重新创建

使用 URL：https://tnho-fasteners.com/api/wechat/callback

---

## 诊断命令

如果以上方案都无法解决，请执行以下诊断命令并提供输出：

### 1. 检查服务状态

```bash
# FastAPI 服务状态
cd /workspace/projects && ./scripts/service.sh status

# Nginx 状态
systemctl status nginx

# 80 端口监听状态
netstat -tuln | grep :80

# 8080 端口监听状态
netstat -tuln | grep :8080
```

### 2. 本地测试

```bash
# 测试本地 FastAPI 服务
curl http://localhost:8080/health

# 测试本地 Nginx
curl http://localhost/

# 测试本地代理（如果方案三已运行）
curl http://localhost/health
```

### 3. 外部测试

```bash
# 从外部测试 8080 端口
curl http://115.190.192.22:8080/health

# 测试域名（如果 Nginx 正常）
curl https://tnho-fasteners.com/health
```

### 4. 查看错误日志

```bash
# FastAPI 服务日志
cd /workspace/projects && ./scripts/service.sh logs

# Nginx 错误日志
tail -50 /var/log/nginx/error.log

# Nginx 系统日志
journalctl -xeu nginx.service
```

---

## 常见错误和解决方法

### 错误 1: 522 Connection timed out

**原因**: Cloudflare 无法连接到源站

**解决**:
- 检查 Nginx 是否运行：`systemctl status nginx`
- 检查 80 端口是否开放：`netstat -tuln | grep :80`
- 检查防火墙规则：`iptables -L -n | grep 80`
- 使用方案二或方案三临时解决

### 错误 2: 502 Bad Gateway

**原因**: Nginx 无法连接到 FastAPI 服务

**解决**:
- 检查 FastAPI 服务：`cd /workspace/projects && ./scripts/service.sh status`
- 检查 8080 端口：`netstat -tuln | grep :8080`
- 重启 FastAPI 服务：`cd /workspace/projects && ./scripts/service.sh restart`

### 错误 3: 404 Not Found

**原因**: 路由配置错误

**解决**:
- 检查 Nginx 配置：`cat /etc/nginx/conf.d/tnho-api.conf`
- 确认 proxy_pass 指向 `http://localhost:8080`
- 重启 Nginx：`systemctl restart nginx`

### 错误 4: 验证失败

**原因**: Token 或 EncodingAESKey 配置错误

**解决**:
- 检查 `.env` 文件配置
- 确保与企业微信管理后台的配置一致
- 重启 FastAPI 服务：`cd /workspace/projects && ./scripts/service.sh restart`

---

## 推荐流程

### 如果您是技术人员

1. 使用方案一修复 Nginx 配置
2. 测试接口访问
3. 重新创建企业微信机器人

### 如果您需要快速解决

1. 使用方案三（Python HTTP 代理）
2. 测试接口访问
3. 重新创建企业微信机器人
4. 后续再配置 Nginx

### 如果需要临时使用

1. 使用方案二（IP 地址）
2. 开放 8080 端口
3. 使用 IP 地址创建机器人

---

## 企业微信创建步骤

### 重新创建机器人

1. 刷新企业微信管理后台页面
2. 点击"创建应用"或"重新创建"
3. 填写以下信息：
   - **应用名称**: TNHO 全能营销助手
   - **应用介绍**: 一键生成产品宣传视频、图片、文案和语音，支持多种营销场景
   - **应用图标**: 上传机器人图标（可选）
   - **可见范围**: 谢宝乐
   - **接收消息设置**:
     - URL: https://tnho-fasteners.com/api/wechat/callback
     - Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
     - EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
4. 点击"创建"
5. 等待验证完成

### 验证是否创建成功

创建成功后，系统会显示：
- 应用 ID（Corp ID）
- 应用 Secret
- Token
- EncodingAESKey

---

## 下一步

1. **选择一个解决方案**: 根据您的情况选择方案一、方案二或方案三
2. **执行修复步骤**: 按照选择的方案执行
3. **测试接口**: 确保接口可以正常访问
4. **重新创建机器人**: 在企业微信管理后台重新创建
5. **验证功能**: 在企业微信中给机器人发送测试消息

---

## 联系支持

如果以上方案都无法解决问题，请提供以下信息：

1. 服务状态：
   ```bash
   systemctl status nginx
   cd /workspace/projects && ./scripts/service.sh status
   ```

2. 端口监听：
   ```bash
   netstat -tuln | grep -E ':(80|8080)'
   ```

3. 错误日志：
   ```bash
   journalctl -xeu nginx.service
   tail -50 /var/log/nginx/error.log
   ```

4. 测试结果：
   ```bash
   curl http://localhost:8080/health
   curl http://localhost/
   curl https://tnho-fasteners.com/health
   ```

5. 企业微信显示的错误信息截图

---

## 更新日志

### 2026-01-14
- ✅ 诊断出企业微信机器人创建失败的原因：接口返回 522 错误
- ✅ 提供三种解决方案：Nginx 配置、IP 临时配置、Python HTTP 代理
- ✅ 创建详细的诊断和故障排查指南
- ⚠️ 等待用户执行解决方案
