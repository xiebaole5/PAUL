# 使用虚拟环境部署 FastAPI 服务

## 问题说明

Ubuntu 24.04 + Python 3.12 的环境受到 PEP 668 限制，无法直接在系统 Python 环境中安装依赖包。即使使用 `--break-system-packages` 选项，某些系统包（如 pip、urllib3）仍然无法卸载。

## 解决方案

使用 Python 虚拟环境来绕过系统包管理限制。虚拟环境是 Python 官方推荐的依赖隔离方案。

## 部署步骤

### 方法一：快速部署（推荐）

```bash
cd /workspace/projects

# 拉取最新代码
git fetch origin
git reset --hard origin/main

# 执行虚拟环境部署脚本
bash fix_venv_deploy.sh
```

### 方法二：手动部署

如果脚本执行失败，可以手动执行以下步骤：

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

# 4. 安装依赖
pip install --upgrade pip
pip install -r requirements.txt

# 5. 启动服务
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
nohup python -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

# 6. 验证服务
sleep 5
curl http://localhost:8080/health
```

## 后续操作

### 重启服务

```bash
bash /workspace/projects/start_with_venv.sh
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

在浏览器中访问：http://localhost:8080/docs

## Nginx 配置

需要配置 Nginx 将 80 端口的流量转发到 FastAPI 的 8080 端口：

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

## 目录结构

```
/workspace/projects/
├── venv/                    # Python 虚拟环境（新）
├── src/
│   ├── main.py
│   └── ...
├── requirements.txt
├── fix_venv_deploy.sh       # 虚拟环境部署脚本（新）
└── start_with_venv.sh       # 启动脚本（新）
```

## 常见问题

### 1. 虚拟环境未激活

确保在执行安装和启动命令前执行：

```bash
source /workspace/projects/venv/bin/activate
```

### 2. 依赖安装失败

删除虚拟环境重新创建：

```bash
rm -rf /workspace/projects/venv
python3 -m venv /workspace/projects/venv
source /workspace/projects/venv/bin/activate
pip install -r /workspace/projects/requirements.txt
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

## 小程序 API 接口

- 脚本生成: `POST /api/generate-script`
- 图片生成: `POST /api/generate-image`
- 视频生成: `POST /api/generate-video`
- 文件上传: `POST /api/upload`
- 健康检查: `GET /api/health`

## 企业微信机器人接口

- 消息回调: `POST /api/wechat/callback`
- 发送消息: `POST /api/wechat/send`

## 技术栈

- Python 3.12
- FastAPI 0.121.2
- LangChain 1.0.3
- LangGraph 1.0.2
- MoviePy 2.2.1
- Uvicorn 0.38.0
