# 服务器虚拟环境部署指南（离线版）

由于 GitHub 网络连接问题，请在服务器上直接执行以下命令：

## 方法一：快速部署（复制粘贴以下所有命令）

```bash
cd /workspace/projects

# 1. 停止旧服务
pkill -9 uvicorn 2>/dev/null || true
pkill -9 python3 2>/dev/null || true
sleep 2

# 2. 创建虚拟环境
python3 -m venv venv

# 3. 激活虚拟环境
source venv/bin/activate

# 4. 升级 pip（使用阿里云镜像）
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

# 5. 安装依赖（使用阿里云镜像，需要5-10分钟）
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

# 6. 创建启动脚本
cat > start_with_venv.sh << 'EOF'
#!/bin/bash
set -e

# 停止旧服务
pkill -9 uvicorn 2>/dev/null || true
pkill -9 python3 2>/dev/null || true
sleep 2

# 激活虚拟环境
cd /workspace/projects
source venv/bin/activate

# 设置环境变量
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH

# 启动 FastAPI 服务（8080端口）
nohup python -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

# 等待服务启动
sleep 5

# 验证服务
echo "=== 服务状态检查 ==="
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✓ 服务启动成功"
    curl -s http://localhost:8080/health
else
    echo "❌ 服务启动失败，查看日志："
    tail -50 /tmp/fastapi.log
fi
EOF

chmod +x start_with_venv.sh

# 7. 启动服务
bash start_with_venv.sh
```

## 方法二：分步执行

### 步骤1：停止旧服务
```bash
cd /workspace/projects
pkill -9 uvicorn 2>/dev/null || true
pkill -9 python3 2>/dev/null || true
sleep 2
```

### 步骤2：创建虚拟环境
```bash
python3 -m venv venv
```

### 步骤3：激活虚拟环境并安装依赖
```bash
source venv/bin/activate
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
```

**注意**：此步骤需要5-10分钟，请耐心等待。

### 步骤4：启动服务
```bash
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
nohup python -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &
```

### 步骤5：验证服务
```bash
sleep 5
curl http://localhost:8080/health
```

## 后续操作

### 重启服务
```bash
cd /workspace/projects
source venv/bin/activate
nohup python -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &
```

### 查看日志
```bash
tail -f /tmp/fastapi.log
```

### 停止服务
```bash
pkill -9 uvicorn
```

### 健康检查
```bash
curl http://localhost:8080/health
```

### 查看 API 文档
在浏览器中访问：http://47.110.72.148:8080/docs

## Nginx 配置（可选）

如果需要将 80 端口流量转发到 8080 端口，请配置 Nginx：

```nginx
server {
    listen 80;
    server_name tnho-fasteners.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

配置后重启 Nginx：

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 常见问题

### 1. 虚拟环境未激活

确保在执行启动命令前执行：

```bash
cd /workspace/projects
source venv/bin/activate
```

### 2. 依赖安装失败

删除虚拟环境重新创建：

```bash
rm -rf /workspace/projects/venv
python3 -m venv /workspace/projects/venv
source /workspace/projects/venv/bin/activate
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
pip install -r /workspace/projects/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
```

### 3. 端口被占用

检查占用端口的进程：

```bash
lsof -i :8080
```

杀死进程：

```bash
kill -9 <PID>
```

### 4. Git 网络连接失败

由于 GitHub 网络连接问题，不需要从 Git 拉取最新代码。直接在服务器上执行上述命令即可。

## 目录结构

```
/workspace/projects/
├── venv/                    # Python 虚拟环境
│   ├── bin/
│   ├── lib/
│   └── ...
├── src/
│   ├── main.py
│   └── ...
├── requirements.txt
└── start_with_venv.sh       # 启动脚本（可选）
```

## 小程序 API 接口

- 脚本生成: `POST /api/generate-script`
- 图片生成: `POST /api/generate-image`
- 视频生成: `POST /api/generate-video`
- 文件上传: `POST /api/upload`
- 健康检查: `GET /api/health`

## 企业微信机器人接口

- 消息回调: `POST /api/wechat/callback`
- 发送消息: `POST /api/wechat/send`
