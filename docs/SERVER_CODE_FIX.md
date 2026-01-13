# 服务器代码完整化修复指南

## 问题诊断

服务器上遇到的错误：
1. `ModuleNotFoundError: No module named 'src.storage.database.init_db'`
2. `ERROR: Error loading ASGI app. Could not import module "app"`

**根本原因**：服务器上的代码不完整，缺少核心业务逻辑文件。

## 快速解决方案

### 步骤 1: 备份现有 .env 文件

```bash
cd /root/tnho-video
cp .env .env.backup
```

### 步骤 2: 删除不完整的代码目录

```bash
cd /root
rm -rf tnho-video
```

### 步骤 3: 从 GitHub 重新克隆完整代码

```bash
cd /root
git clone https://github.com/xiebaole5/PAUL.git tnho-video
cd tnho-video
```

### 步骤 4: 恢复 .env 配置

```bash
cd /root/tnho-video

# 如果需要，恢复之前的配置
# cp ../.env.backup .env

# 或者创建新的 .env 文件
cat > .env << 'EOF'
# 火山方舟配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 对象存储配置
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing

# 数据库配置
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5433/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF
```

### 步骤 5: 创建虚拟环境并安装依赖

```bash
cd /root/tnho-video

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装核心依赖
pip install fastapi uvicorn python-multipart \
  langchain langchain-openai langgraph \
  langgraph-checkpoint-postgres \
  openai tiktoken \
  SQLAlchemy psycopg2-binary alembic \
  moviepy imageio-ffmpeg ImageIO opencv-python \
  coze-coding-dev-sdk volcengine-python-sdk boto3 \
  requests httpx python-dotenv pydantic pyyaml \
  APScheduler -i https://mirrors.aliyun.com/pypi/simple/ -q
```

### 步骤 6: 使用现有数据库

```bash
# 数据库已经在端口 5433 上运行，无需重新启动
# 检查数据库状态
docker ps | grep tnho-db
```

### 步骤 7: 初始化数据库

```bash
cd /root/tnho-video
source venv/bin/activate

# 初始化数据库
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('✅ 数据库初始化完成')
"
```

### 步骤 8: 启动应用

```bash
cd /root/tnho-video
source venv/bin/activate

# 创建日志目录
mkdir -p logs

# 停止旧服务
pkill -f uvicorn || true

# 启动服务
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &

# 等待服务启动
sleep 10
```

### 步骤 9: 测试服务

```bash
# 测试健康检查
curl http://localhost:8000/health

# 查看 API 文档
curl http://localhost:8000/docs

# 查看应用日志
tail -f logs/app.log
```

## 验证代码完整性

```bash
cd /root/tnho-video

# 检查关键文件是否存在
echo "检查关键文件："
test -f app.py && echo "✅ app.py 存在" || echo "❌ app.py 缺失"
test -f requirements.txt && echo "✅ requirements.txt 存在" || echo "❌ requirements.txt 缺失"
test -d src/agents && echo "✅ src/agents 目录存在" || echo "❌ src/agents 目录缺失"
test -d src/api && echo "✅ src/api 目录存在" || echo "❌ src/api 目录缺失"
test -d src/storage && echo "✅ src/storage 目录存在" || echo "❌ src/storage 目录缺失"
test -f src/storage/database/init_db.py && echo "✅ src/storage/database/init_db.py 存在" || echo "❌ src/storage/database/init_db.py 缺失"

# 列出目录结构
echo ""
echo "项目根目录："
ls -la

echo ""
echo "src 目录结构："
tree src/ || find src/ -type d -maxdepth 3
```

## 完整部署脚本（一键执行）

创建文件 `/root/complete_deploy.sh`：

```bash
#!/bin/bash
# 完整部署脚本 - 重新克隆代码并部署

set -e

echo "=========================================="
echo "TNHO 视频生成服务 - 完整部署"
echo "=========================================="
echo ""

# 备份 .env
echo "步骤 1: 备份配置文件..."
cd /root
if [ -f "tnho-video/.env" ]; then
    cp tnho-video/.env .env.backup
    echo "✅ .env 已备份"
fi

# 删除旧代码
echo "步骤 2: 删除不完整的代码..."
rm -rf tnho-video

# 克隆新代码
echo "步骤 3: 从 GitHub 克隆完整代码..."
git clone https://github.com/xiebaole5/PAUL.git tnho-video
cd tnho-video

# 恢复 .env
echo "步骤 4: 恢复配置文件..."
if [ -f "../.env.backup" ]; then
    cp ../.env.backup .env
    echo "✅ .env 已恢复"
else
    cat > .env << 'EOF'
# 火山方舟配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 对象存储配置
S3_ENDPOINT=https://tos-s3-cn-beijing.volces.com
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_BUCKET=tnho-videos
S3_REGION=cn-beijing

# 数据库配置
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5433/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF
    echo "⚠️  请编辑 .env 文件，修改 S3 配置项"
fi

# 创建虚拟环境
echo "步骤 5: 创建虚拟环境..."
python3 -m venv venv
source venv/bin/activate

# 安装依赖
echo "步骤 6: 安装 Python 依赖..."
pip install fastapi uvicorn python-multipart \
  langchain langchain-openai langgraph \
  langgraph-checkpoint-postgres \
  openai tiktoken \
  SQLAlchemy psycopg2-binary alembic \
  moviepy imageio-ffmpeg ImageIO opencv-python \
  coze-coding-dev-sdk volcengine-python-sdk boto3 \
  requests httpx python-dotenv pydantic pyyaml \
  APScheduler -i https://mirrors.aliyun.com/pypi/simple/ -q

echo "✅ 依赖安装完成"

# 检查数据库
echo "步骤 7: 检查数据库状态..."
if docker ps | grep -q "tnho-db"; then
    echo "✅ 数据库容器已运行"
else
    echo "⚠️  数据库容器未运行，启动中..."
    docker run -d \
      --name tnho-db \
      -e POSTGRES_DB=tnho_video \
      -e POSTGRES_USER=postgres \
      -e POSTGRES_PASSWORD=postgres123 \
      -p 5433:5432 \
      postgres:15-alpine
    sleep 10
fi

# 初始化数据库
echo "步骤 8: 初始化数据库..."
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('✅ 数据库初始化完成')
"

# 启动应用
echo "步骤 9: 启动应用..."
pkill -f uvicorn || true
mkdir -p logs

nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &
APP_PID=$!

echo "✅ 应用已启动，PID: $APP_PID"

# 等待服务启动
echo "步骤 10: 等待服务启动..."
sleep 10

# 测试服务
echo "步骤 11: 测试服务..."
if curl -f http://localhost:8000/health; then
    echo ""
    echo "=========================================="
    echo "✅ 部署成功！服务正常运行"
    echo "=========================================="
    echo ""
    echo "访问地址："
    echo "  API 文档: http://tnho-fasteners.com/docs"
    echo "  健康检查: http://tnho-fasteners.com/health"
    echo "  本地访问: http://localhost:8000/health"
    echo ""
    echo "常用命令："
    echo "  查看日志: tail -f /root/tnho-video/logs/app.log"
    echo "  重启服务: pkill -f uvicorn; cd /root/tnho-video; source venv/bin/activate; nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &"
    echo "  停止服务: pkill -f uvicorn"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 服务启动失败"
    echo "=========================================="
    echo ""
    echo "查看日志："
    echo "  tail -n 50 /root/tnho-video/logs/app.log"
    echo ""
    echo "手动启动测试："
    echo "  cd /root/tnho-video"
    echo "  source venv/bin/activate"
    echo "  venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000"
    echo ""
fi
```

执行完整部署：

```bash
# 创建部署脚本
cat > /root/complete_deploy.sh << 'EOF'
# 上面的完整部署脚本内容
EOF

# 赋予执行权限
chmod +x /root/complete_deploy.sh

# 执行部署
bash /root/complete_deploy.sh
```

## 常见问题

### Q: 克隆代码失败？

A: 检查网络连接和 GitHub 访问：

```bash
# 测试 GitHub 连接
ping github.com

# 使用 HTTPS 克隆
git clone https://github.com/xiebaole5/PAUL.git tnho-video
```

### Q: 依赖安装失败？

A: 使用阿里云镜像源并重试：

```bash
cd /root/tnho-video
source venv/bin/activate
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
```

### Q: 数据库连接失败？

A: 检查数据库容器状态：

```bash
# 检查容器状态
docker ps | grep tnho-db

# 查看数据库日志
docker logs tnho-db

# 测试连接
docker exec -it tnho-db psql -U postgres -c "SELECT 1;"
```

### Q: 应用启动失败？

A: 查看详细日志：

```bash
cd /root/tnho-video
cat logs/app.log

# 或手动启动查看错误
source venv/bin/activate
venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

## 下一步

完成部署后：
1. 访问 API 文档：http://tnho-fasteners.com/docs
2. 测试视频生成功能
3. 修改 .env 文件中的 S3 配置（真实值）
4. 配置微信小程序连接后端 API
