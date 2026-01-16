# 服务器快速部署指南

## 问题诊断

如果在服务器上遇到 `No such file or directory` 或 `ModuleNotFoundError: No module named 'src'` 错误，请按以下步骤操作：

---

## 方案一：使用部署脚本（推荐）⭐

### 1. 下载并运行诊断脚本

```bash
# 克隆或更新代码
git clone https://github.com/xiebaole5/PAUL.git /tmp/PAUL
cd /tmp/PAUL

# 运行诊断脚本
bash scripts/diagnose_server.sh
```

### 2. 找到项目目录后，运行部署脚本

```bash
# 假设你的项目在 /root/PAUL
cd /root/PAUL

# 运行部署脚本
bash scripts/deploy_server.sh
```

---

## 方案二：手动部署

### 1. 找到项目目录

```bash
# 搜索 PAUL 项目目录
find / -name "PAUL" -type d 2>/dev/null

# 或者搜索包含 .git 的目录
find / -name ".git" -type d 2>/dev/null | grep PAUL
```

### 2. 进入项目目录并更新

```bash
# 假设项目在 /root/PAUL（请替换为实际路径）
cd /root/PAUL

# 拉取最新代码
git pull origin main
```

### 3. 停止旧服务

```bash
# 停止所有相关进程
pkill -f "uvicorn src.main:app"
sleep 2
```

### 4. 启动新服务

```bash
# 设置 PYTHONPATH（重要！）
export PYTHONPATH=$(pwd):$(pwd)/src

# 启动服务（使用系统 Python）
nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/miniprogram_backend.log 2>&1 &

# 或者使用虚拟环境（如果有）
# source venv/bin/activate
# nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/miniprogram_backend.log 2>&1 &
```

### 5. 验证服务

```bash
# 检查进程
ps aux | grep uvicorn

# 检查端口
netstat -tlnp | grep 8080

# 健康检查
curl http://localhost:8080/health

# 查看日志
tail -f /tmp/miniprogram_backend.log
```

---

## 常见问题

### ❌ 错误：`ModuleNotFoundError: No module named 'src'`

**原因**：Python 找不到 src 模块

**解决方法**：
```bash
# 设置 PYTHONPATH
export PYTHONPATH=$(pwd):$(pwd)/src

# 然后再启动服务
python3 -m uvicorn src.main:app ...
```

---

### ❌ 错误：`No such file or directory: /path/to/PAUL`

**原因**：`/path/to/PAUL` 是示例路径，不是实际路径

**解决方法**：
```bash
# 查找实际的项目目录
find / -name "PAUL" -type d 2>/dev/null
```

---

### ❌ 错误：端口 8080 已被占用

**解决方法**：
```bash
# 查找占用端口的进程
lsof -i :8080

# 或者
netstat -tlnp | grep 8080

# 停止旧进程
pkill -f "uvicorn src.main:app"
```

---

## Nginx 配置检查

如果使用 Nginx 反向代理，确保配置正确：

```nginx
server {
    listen 80;
    server_name tnho-fasteners.com 47.110.72.148;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

重新加载 Nginx：
```bash
# 检查配置
nginx -t

# 重新加载
nginx -s reload

# 或者重启
systemctl restart nginx
```

---

## 验证部署成功

### 1. 本地测试

```bash
# 健康检查
curl http://localhost:8080/health

# 预期输出：{"status":"healthy"}
```

### 2. 外部测试

```bash
# 从外部服务器测试
curl http://47.110.72.148/health

# 或通过域名
curl http://tnho-fasteners.com/health
```

### 3. 小程序测试

在微信开发者工具中：
1. 打开小程序
2. 查看控制台日志，确认健康检查通过
3. 测试上传图片功能

---

## 查看日志

### 后端日志
```bash
tail -f /tmp/miniprogram_backend.log
```

### Nginx 日志
```bash
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## 完整的一键部署命令

如果你的项目在 `/root/PAUL`，可以复制以下命令：

```bash
# 一键部署
cd /root/PAUL && \
git pull origin main && \
pkill -f "uvicorn src.main:app" && \
sleep 2 && \
export PYTHONPATH=$(pwd):$(pwd)/src && \
nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/miniprogram_backend.log 2>&1 & \
sleep 5 && \
curl http://localhost:8080/health
```

---

## 需要帮助？

如果还有问题，请提供以下信息：

1. 项目目录路径（`pwd`）
2. 诊断脚本输出（`bash scripts/diagnose_server.sh`）
3. 错误日志（`tail -100 /tmp/miniprogram_backend.log`）
