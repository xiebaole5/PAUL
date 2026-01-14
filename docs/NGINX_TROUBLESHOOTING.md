# Nginx 配置冲突问题诊断与修复

## 问题诊断

### 当前状态

从您的执行结果可以看到以下问题：

#### 1. 配置冲突警告
```
2026/01/14 23:35:44 [warn] 38150#38150: conflicting server name "tnho-fasteners.com" on 0.0.0.0:80, ignored
```
**说明**: 有多个配置文件配置了相同的 server_name `tnho-fasteners.com`

#### 2. Nginx 重启失败
```
Job for nginx.service failed because the control process exited with error code.
```
**说明**: Nginx 启动或重启时出错

#### 3. 接口返回 404
```
{"detail":"Not Found"}
```
**说明**: Nginx 可能在运行，但是路由配置有问题，找不到 `/api/wechat/test` 路径

## 诊断步骤

### 步骤 1: 查找所有 Nginx 配置文件

在服务器上执行以下命令：

```bash
# 查找所有 Nginx 配置文件
find /etc/nginx -name "*.conf" 2>/dev/null

# 查找所有包含 "tnho-fasteners.com" 的配置文件
grep -r "tnho-fasteners.com" /etc/nginx/ 2>/dev/null
```

### 步骤 2: 查看详细的错误信息

```bash
# 查看 Nginx 状态和错误信息
systemctl status nginx.service

# 查看详细错误日志
journalctl -xeu nginx.service

# 查看 Nginx 错误日志
tail -50 /var/log/nginx/error.log
```

### 步骤 3: 查看启用的配置

```bash
# 查看 sites-enabled 目录
ls -la /etc/nginx/sites-enabled/

# 查看 conf.d 目录
ls -la /etc/nginx/conf.d/

# 查看 nginx.conf 主配置文件
cat /etc/nginx/nginx.conf
```

## 常见原因和解决方案

### 原因 1: 有多个配置文件配置了相同的 server_name

**症状**: `conflicting server name "tnho-fasteners.com" on 0.0.0.0:80, ignored`

**解决方案**:

#### 方案 A: 禁用所有其他配置文件，只保留我们创建的

```bash
# 备份所有配置
cp -r /etc/nginx/sites-available /etc/nginx/sites-available.backup
cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup

# 禁用所有配置
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/conf.d/*.conf

# 只启用我们创建的配置
ln -sf /etc/nginx/sites-available/tnho-api /etc/nginx/sites-enabled/

# 测试配置
nginx -t

# 如果测试通过，重启 Nginx
systemctl restart nginx
```

#### 方案 B: 查找并删除冲突的配置

```bash
# 查找所有包含 "tnho-fasteners.com" 的配置文件
grep -rl "tnho-fasteners.com" /etc/nginx/

# 假设找到了 /etc/nginx/conf.d/tnho.conf 和 /etc/nginx/sites-enabled/tnho-api

# 删除或禁用冲突的配置
rm /etc/nginx/conf.d/tnho.conf

# 测试配置
nginx -t

# 如果测试通过，重启 Nginx
systemctl restart nginx
```

---

### 原因 2: 配置文件路径问题

**症状**: `/etc/nginx/sites-enabled/` 目录不存在

**解决方案**:

如果 `sites-enabled` 目录不存在，可以在 `conf.d` 目录中配置：

```bash
# 删除我们创建的配置
rm /etc/nginx/sites-enabled/tnho-api
rm /etc/nginx/sites-available/tnho-api

# 在 conf.d 目录创建配置
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

# 测试配置
nginx -t

# 如果测试通过，重启 Nginx
systemctl restart nginx
```

---

### 原因 3: Nginx 配置文件有语法错误

**症状**: Nginx 无法启动或重启失败

**解决方案**:

```bash
# 测试配置文件
nginx -t

# 如果有错误，查看详细错误信息
nginx -t 2>&1 | grep error

# 修正配置文件中的错误
nano /etc/nginx/conf.d/tnho-api.conf

# 重新测试
nginx -t

# 如果测试通过，重启 Nginx
systemctl restart nginx
```

---

### 原因 4: 端口被占用

**症状**: `bind() to 0.0.0.0:80 failed (98: Address already in use)`

**解决方案**:

```bash
# 查看哪个进程占用了 80 端口
netstat -tuln | grep :80
lsof -i :80

# 如果是其他服务占用，可以停止该服务或修改 Nginx 监听端口

# 临时方案：修改 Nginx 监听端口为 8080
# 编辑配置文件
nano /etc/nginx/conf.d/tnho-api.conf

# 将 listen 80; 改为 listen 8080;

# 重启 Nginx
systemctl restart nginx

# 然后企业微信回调 URL 改为: http://tnho-fasteners.com:8080/api/wechat/callback
```

---

### 原因 5: FastAPI 服务未运行

**症状**: `502 Bad Gateway`

**解决方案**:

```bash
# 检查 FastAPI 服务状态
cd /workspace/projects && ./scripts/service.sh status

# 如果服务未运行，启动服务
cd /workspace/projects && ./scripts/service.sh restart

# 测试本地访问
curl http://localhost:8080/health
```

---

## 快速修复步骤

根据您的具体情况，执行以下步骤之一：

### 修复方案 1: 清理所有配置，重新创建（推荐）

```bash
# 1. 停止 Nginx
systemctl stop nginx

# 2. 备份配置
cp -r /etc/nginx /etc/nginx.backup.$(date +%Y%m%d_%H%M%S)

# 3. 删除所有配置
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/conf.d/*.conf

# 4. 创建新的配置
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

# 6. 如果测试通过，启动 Nginx
systemctl start nginx

# 7. 检查 Nginx 状态
systemctl status nginx

# 8. 测试接口
curl https://tnho-fasteners.com/api/wechat/test
```

---

### 修复方案 2: 使用现有的 80 端口配置（如果 Nginx 已经在运行）

如果 Nginx 已经在运行并配置了 80 端口，可以直接测试：

```bash
# 测试企业微信接口
curl https://tnho-fasteners.com/api/wechat/test

# 如果返回 {"status":"ok", ...}，说明配置已经成功
# 如果返回 {"detail":"Not Found"}，需要检查 Nginx 配置

# 查看当前运行的 Nginx 配置
curl -I http://localhost/

# 查看 Nginx 日志
tail -20 /var/log/nginx/access.log
tail -20 /var/log/nginx/error.log
```

---

## 验证步骤

### 1. 检查 Nginx 状态

```bash
systemctl status nginx
```

应该显示：`active (running)`

### 2. 测试接口

```bash
# 测试健康检查
curl https://tnho-fasteners.com/health

# 应该返回: {"status":"ok"}

# 测试企业微信接口
curl https://tnho-fasteners.com/api/wechat/test

# 应该返回: {"status":"ok","message":"企业微信接口正常",...}
```

### 3. 在企业微信中验证

1. 登录企业微信管理后台
2. 找到"TNHO全能营销助手"机器人
3. 点击"接收消息" -> "设置API接收"
4. 点击"验证"按钮
5. 应该显示"验证成功"

---

## 如果以上方案都无法解决

请提供以下信息：

### 1. Nginx 配置文件

```bash
cat /etc/nginx/nginx.conf
cat /etc/nginx/conf.d/*.conf
ls -la /etc/nginx/sites-enabled/
```

### 2. 错误日志

```bash
systemctl status nginx.service
journalctl -xeu nginx.service
tail -50 /var/log/nginx/error.log
```

### 3. 网络状态

```bash
netstat -tuln | grep -E ':(80|443|8080)'
lsof -i :80
lsof -i :8080
```

### 4. 端口测试

```bash
curl -I http://localhost/
curl -I http://localhost:8080/health
curl -I http://115.190.192.22/
```

---

## 联系支持

如果需要进一步帮助，请将以上命令的输出发给我，我将帮您进一步诊断问题。

---

## 更新日志

### 2026-01-14
- ✅ 诊断出配置冲突问题
- ✅ 提供多种修复方案
- ⚠️ 等待用户执行修复方案
