# 服务器同步操作指南

## ✅ Git推送成功

已成功将最新代码推送到GitHub仓库：https://github.com/xiebaole5/PAUL.git

推送的提交包括：
- ✅ start_service.sh - 基础启动脚本
- ✅ start_service_v2.sh - 改进版启动脚本（自动检测路径）
- ✅ diagnose.sh - 诊断工具
- ✅ restart_service.sh - 重启脚本（含模块测试）
- ✅ quick_fix.sh - 快速修复脚本
- ✅ DEPLOYMENT.md - 完整部署文档
- ✅ 修复了端口冲突问题（9000→8080）

## 🚀 服务器操作步骤

### 第一步：拉取最新代码

在服务器47.110.72.148上执行：

```bash
cd /workspace/projects
git pull origin main
```

### 第二步：使用最新的启动脚本

```bash
# 使用改进版启动脚本（自动检测路径）
bash start_service_v2.sh
```

### 第三步：验证服务

```bash
# 测试健康检查
curl http://localhost:8080/health

# 测试脚本生成接口
curl -X POST http://localhost:8080/api/generate-script \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "螺母",
    "product_image_url": "http://example.com/image.jpg",
    "usage_scenario": "建筑",
    "theme_direction": "高品质"
  }'
```

### 第四步：配置Nginx（如果还未配置）

```bash
# 创建Nginx配置
cat > /etc/nginx/sites-available/tnho-fasteners << 'EOF'
server {
    listen 80;
    server_name 47.110.72.148 tnho-fasteners.com;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        access_log off;
    }
}
EOF

# 启用配置
ln -s /etc/nginx/sites-available/tnho-fasteners /etc/nginx/sites-enabled/

# 测试配置
nginx -t

# 重启Nginx
systemctl restart nginx

# 验证Nginx
curl http://47.110.72.148/health
```

## 📋 完整同步命令（一键复制）

```bash
# === 完整同步和启动流程 ===

# 1. 停止旧服务
pkill -9 -f uvicorn
sleep 3

# 2. 拉取最新代码
cd /workspace/projects
git fetch origin
git reset --hard origin/main
git clean -fd

# 3. 查看最新文件
ls -la *.sh *.md 2>/dev/null | head -10

# 4. 使用最新脚本启动
bash start_service_v2.sh

# 5. 如果启动失败，查看日志
tail -50 /tmp/fastapi.log
```

## 🔍 问题排查

### 如果Git拉取失败

```bash
# 检查Git配置
git remote -v

# 重新配置远程仓库
git remote set-url origin https://github.com/xiebaole5/PAUL.git

# 拉取代码
git pull origin main
```

### 如果启动脚本无法执行

```bash
# 添加执行权限
chmod +x *.sh

# 再次执行
bash start_service_v2.sh
```

### 如果仍然404

```bash
# 使用诊断脚本
bash diagnose.sh

# 查看详细日志
cat /tmp/fastapi.log

# 手动测试模块导入
cd /workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
python3 -c "from agents.miniprogram_video_agent import build_agent; print('✅ 模块正常')"
```

## 📊 验证清单

在服务器上执行以下命令，确认所有功能正常：

```bash
# 1. 服务状态
ps aux | grep uvicorn | grep -v grep

# 2. 端口监听
netstat -tlnp | grep 8080

# 3. 健康检查
curl http://localhost:8080/health

# 4. API测试
curl http://localhost:8080/api/generate-script \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"product_name":"测试","product_image_url":"http://test.com/img.jpg","usage_scenario":"测试","theme_direction":"测试"}'

# 5. 外部访问（Nginx配置后）
curl http://47.110.72.148/health
```

## 🎯 成功标志

执行成功后，应该看到：

1. ✅ 服务进程运行中
2. ✅ 8080端口正常监听
3. ✅ `/health` 返回 `{"status":"healthy"}`
4. ✅ `/api/generate-script` 返回脚本内容
5. ✅ 小程序可以正常调用接口

## 📞 下一步

1. 在服务器上执行上述命令
2. 配置Nginx反向代理
3. 测试小程序功能
4. 如有问题，发送以下信息给我：
   - `tail -100 /tmp/fastapi.log` 的输出
   - `git log --oneline -5` 的输出
   - `curl http://localhost:8080/health` 的输出
