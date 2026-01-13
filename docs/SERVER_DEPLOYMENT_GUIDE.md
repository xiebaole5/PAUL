# 天虹紧固件视频生成服务 - 服务器部署指南

## 📋 部署说明

本指南适用于在阿里云服务器（47.110.72.148）上部署天虹紧固件视频生成服务。

**部署方式：轻量化部署**
- 数据库：使用 Docker 容器运行 PostgreSQL
- 应用：直接使用 Python 运行（不使用 Docker 构建，避免资源耗尽）

## 🚀 一键部署命令

请按顺序在服务器上执行以下命令：

### 1. 备份旧配置（如果有）

```bash
# 备份配置文件
cd /root/tnho-video && cp .env .env.backup 2>/dev/null || true
```

### 2. 克隆最新代码

```bash
# 删除旧代码
cd /root
rm -rf tnho-video

# 克隆最新代码
git clone https://github.com/xiebaole5/PAUL.git tnho-video
cd tnho-video

# 恢复配置文件（如果有备份）
cp ../.env.backup .env 2>/dev/null || true
```

### 3. 创建虚拟环境

```bash
python3 -m venv venv
source venv/bin/activate
```

### 4. 安装依赖

```bash
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
```

### 5. 配置环境变量

如果 `.env` 文件不存在，请创建：

```bash
cat > .env << 'EOF'
# 火山方舟 API 配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_ENDPOINT_URL=https://ark.cn-beijing.volces.com/api/v3

# 数据库配置（Docker 容器）
PGDATABASE_URL=postgresql://postgres:postgres@localhost:5433/tnho_video

# 对象存储配置（需要修改为实际的 S3 凭证）
S3_ENDPOINT_URL=https://s3.amazonaws.com
S3_ACCESS_KEY_ID=your-access-key-id
S3_SECRET_ACCESS_KEY=your-secret-access-key
S3_BUCKET=your-bucket-name
S3_REGION=us-east-1

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
COZE_WORKSPACE_PATH=/root/tnho-video
EOF
```

**⚠️ 重要：请修改 S3 配置为实际的对象存储凭证！**

### 6. 启动 PostgreSQL 数据库容器

```bash
# 停止并删除旧容器（如果有）
docker stop tnho-postgres 2>/dev/null || true
docker rm tnho-postgres 2>/dev/null || true

# 启动新容器
docker run -d \
    --name tnho-postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=tnho_video \
    -p 5433:5432 \
    postgres:15-alpine

# 等待数据库初始化
sleep 5
```

### 7. 初始化数据库表

```bash
# 初始化数据库（添加项目路径到 Python 路径）
python3 -c "
import sys
import os
sys.path.insert(0, '/root/tnho-video')
os.environ['COZE_WORKSPACE_PATH'] = '/root/tnho-video'
from src.storage.database.init_db import init_db
init_db()
print('✅ 数据库初始化完成')
"
```

### 8. 启动应用服务

```bash
# 停止旧服务
pkill -f "uvicorn app:app" || true

# 创建日志目录
mkdir -p logs

# 启动服务
nohup venv/bin/python -m uvicorn app:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --log-level info \
    > logs/app.log 2>&1 &

# 查看启动状态
sleep 3
tail -f logs/app.log
```

### 9. 验证服务状态

```bash
# 测试健康检查
curl http://localhost:8000/health

# 测试 API 文档
curl http://localhost:8000/docs

# 通过公网访问
curl http://47.110.72.148:8000/health

# 通过域名访问
curl http://tnho-fasteners.com/health
```

## 📝 常用命令

### 查看服务日志
```bash
tail -f logs/app.log
```

### 停止服务
```bash
pkill -f "uvicorn app:app"
```

### 重启服务
```bash
pkill -f "uvicorn app:app"
sleep 2
source venv/bin/activate
nohup venv/bin/python -m uvicorn app:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --log-level info \
    > logs/app.log 2>&1 &
```

### 进入虚拟环境
```bash
cd /root/tnho-video
source venv/bin/activate
```

### 检查数据库容器状态
```bash
docker ps | grep tnho-postgres
```

### 查看数据库日志
```bash
docker logs tnho-postgres
```

### 连接数据库
```bash
docker exec -it tnho-postgres psql -U postgres -d tnho_video
```

## 🔍 故障排查

### 问题 1：服务启动失败，提示模块找不到

**原因**：Python 路径配置问题

**解决方案**：
```bash
# 确保使用项目根目录的 app.py 启动
cd /root/tnho-video
ls -la app.py  # 确认文件存在
```

### 问题 2：数据库连接失败

**原因**：PostgreSQL 容器未启动或端口配置错误

**解决方案**：
```bash
# 检查容器状态
docker ps | grep tnho-postgres

# 重启容器
docker restart tnho-postgres

# 检查端口监听
netstat -tuln | grep 5433
```

### 问题 3：API 返回 502 Bad Gateway

**原因**：Nginx 无法连接到后端服务

**解决方案**：
```bash
# 检查后端服务是否运行
ps aux | grep uvicorn

# 检查 8000 端口是否监听
netstat -tuln | grep 8000

# 查看 Nginx 配置
cat /etc/nginx/sites-available/tnho-fasteners.com
```

### 问题 4：pip 安装依赖失败

**原因**：网络问题或缺少系统依赖

**解决方案**：
```bash
# 使用阿里云镜像
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

# 如果缺少系统依赖
apt-get update
apt-get install -y python3-dev build-essential libpq-dev
```

## 📊 项目结构

```
/root/tnho-video/
├── app.py                          # 应用入口（项目根目录）
├── src/
│   ├── api/
│   │   └── app.py                  # FastAPI 应用主逻辑
│   ├── agents/
│   │   └── agent.py                # Agent 定义
│   ├── storage/
│   │   ├── database/
│   │   │   ├── db.py               # 数据库连接
│   │   │   ├── init_db.py          # 数据库初始化
│   │   │   └── video_task_manager.py # 任务管理
│   │   └── s3/
│   │       └── s3_storage.py       # 对象存储
│   └── tools/
│       ├── video_generation_tool.py    # 视频生成工具
│       └── ...
├── config/
│   └── agent_llm_config.json       # LLM 配置
├── requirements.txt                 # Python 依赖
├── .env                            # 环境变量
├── logs/
│   └── app.log                     # 应用日志
└── venv/                           # Python 虚拟环境
```

## 🔐 安全提醒

1. **不要**将 `.env` 文件提交到 Git 仓库
2. **不要**在生产环境中使用默认密码
3. **建议**配置防火墙规则，限制数据库端口访问
4. **建议**定期备份数据库数据

## 📞 支持

如遇到问题，请查看：
1. 应用日志：`logs/app.log`
2. 数据库日志：`docker logs tnho-postgres`
3. Nginx 日志：`/var/log/nginx/error.log`

---

**部署完成后，请访问 http://tnho-fasteners.com/docs 查看 API 文档**
