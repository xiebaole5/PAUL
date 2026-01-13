# 服务器部署修复指南

## 问题分析

当前遇到的问题：
1. **dbus-python 安装失败**：这是 certbot 的依赖，但项目不需要 certbot
2. **依赖安装不完整**：因为 dbus-python 失败导致整个安装被中断
3. **应用启动失败**：需要查看日志了解具体原因
4. **数据库端口冲突**：5432 端口已被占用

## 修复步骤

### 步骤 1: 清理并重新安装依赖（跳过失败包）

```bash
cd /root/tnho-video
source venv/bin/activate

# 方法一：跳过失败的 dbus-python，继续安装其他包
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --no-deps || \
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ 2>&1 | grep -v "dbus-python"
```

或者直接安装核心依赖：

```bash
cd /root/tnho-video
source venv/bin/activate

# 安装核心依赖包（跳过 certbot 等不必要的包）
pip install fastapi uvicorn python-multipart \
  langchain langchain-openai langgraph \
  langgraph-checkpoint-postgres \
  openai tiktoken \
  SQLAlchemy psycopg2-binary alembic \
  moviepy imageio-ffmpeg ImageIO opencv-python \
  coze-coding-dev-sdk volcengine-python-sdk boto3 \
  requests httpx python-dotenv pydantic pyyaml \
  APScheduler -i https://mirrors.aliyun.com/pypi/simple/
```

### 步骤 2: 检查应用启动日志

```bash
cd /root/tnho-video
cat logs/app.log
```

如果日志文件不存在或为空，尝试手动启动查看错误：

```bash
cd /root/tnho-video
source venv/bin/activate
venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

### 步骤 3: 处理数据库端口冲突

5432 端口已被占用，有几个选择：

**选择 A：使用现有的 PostgreSQL 实例**

```bash
# 检查是否有 PostgreSQL 在运行
ps aux | grep postgres

# 如果有，检查它的配置
netstat -tlnp | grep 5432

# 修改 .env 文件，使用现有的数据库
nano .env
# 修改 PGDATABASE_URL 为正确的连接字符串
```

**选择 B：使用不同端口**

```bash
# 停止并删除现有容器
docker stop tnho-db 2>/dev/null || true
docker rm tnho-db 2>/dev/null || true

# 使用不同端口（5433）启动
docker run -d \
  --name tnho-db \
  -e POSTGRES_DB=tnho_video \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -p 5433:5432 \
  postgres:15-alpine

# 等待数据库启动
sleep 10

# 修改 .env 文件，使用新端口
sed -i 's/:5432\//:5433\//' .env
```

**选择 C：停止占用 5432 端口的进程**

```bash
# 查找占用端口的进程
lsof -i:5432

# 如果是系统 PostgreSQL，考虑停止它
systemctl stop postgresql 2>/dev/null || true

# 然后启动 Docker 容器
docker stop tnho-db 2>/dev/null || true
docker rm tnho-db 2>/dev/null || true
docker run -d \
  --name tnho-db \
  -e POSTGRES_DB=tnho_video \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -p 5432:5432 \
  postgres:15-alpine

# 等待数据库启动
sleep 10
```

### 步骤 4: 初始化数据库

```bash
cd /root/tnho-video
source venv/bin/activate

# 初始化数据库表
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('数据库初始化完成')
"
```

### 步骤 5: 重新启动应用

```bash
cd /root/tnho-video
source venv/bin/activate

# 停止旧服务
pkill -f uvicorn || true

# 启动新服务
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &

# 等待服务启动
sleep 10

# 测试健康检查
curl http://localhost:8000/health
```

## 快速修复命令（一键执行）

```bash
#!/bin/bash
# 快速修复脚本

cd /root/tnho-video
source venv/bin/activate

echo "步骤 1: 安装核心依赖..."
pip install fastapi uvicorn python-multipart \
  langchain langchain-openai langgraph \
  langgraph-checkpoint-postgres \
  openai tiktoken \
  SQLAlchemy psycopg2-binary alembic \
  moviepy imageio-ffmpeg ImageIO opencv-python \
  coze-coding-dev-sdk volcengine-python-sdk boto3 \
  requests httpx python-dotenv pydantic pyyaml \
  APScheduler -i https://mirrors.aliyun.com/pypi/simple/ -q

echo "步骤 2: 使用不同端口启动数据库..."
docker stop tnho-db 2>/dev/null || true
docker rm tnho-db 2>/dev/null || true
docker run -d \
  --name tnho-db \
  -e POSTGRES_DB=tnho_video \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -p 5433:5432 \
  postgres:15-alpine

echo "步骤 3: 更新数据库配置..."
sed -i 's/:5432\//:5433\//' .env

echo "步骤 4: 等待数据库启动..."
sleep 10

echo "步骤 5: 初始化数据库..."
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('数据库初始化完成')
" 2>/dev/null || echo "数据库可能已初始化"

echo "步骤 6: 启动应用..."
pkill -f uvicorn || true
mkdir -p logs
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &

echo "步骤 7: 等待服务启动..."
sleep 10

echo "步骤 8: 测试服务..."
curl http://localhost:8000/health

echo ""
echo "完成！查看日志：tail -f logs/app.log"
```

## 验证部署

```bash
# 测试健康检查
curl http://localhost:8000/health

# 测试 API 文档
curl http://localhost:8000/docs

# 查看应用日志
tail -f logs/app.log

# 检查数据库连接
docker exec -it tnho-db psql -U postgres -c "SELECT 1;"
```

## 常见问题

### Q: pip install 仍然失败？

A: 尝试单独安装失败的包，或使用 `--no-deps` 跳过依赖检查：

```bash
pip install <package_name> -i https://mirrors.aliyun.com/pypi/simple/ --no-deps
```

### Q: 应用仍然无法启动？

A: 查看详细日志：

```bash
cat logs/app.log
```

或手动启动查看错误：

```bash
venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

### Q: 数据库连接失败？

A: 检查数据库容器状态和配置：

```bash
# 检查容器状态
docker ps | grep tnho-db

# 检查数据库日志
docker logs tnho-db

# 测试数据库连接
docker exec -it tnho-db psql -U postgres -c "SELECT 1;"
```

### Q: 对象存储配置错误？

A: 编辑 .env 文件，修改 S3 配置：

```bash
nano .env
```

确保以下配置正确：
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- `S3_BUCKET`
- `S3_ENDPOINT`
