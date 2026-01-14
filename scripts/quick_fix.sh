#!/bin/bash
# 快速修复脚本 - 解决服务器部署问题
# 在服务器上执行: bash scripts/quick_fix.sh

set -e

echo "=========================================="
echo "TNHO 视频生成服务 - 快速修复"
echo "=========================================="
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# 步骤 1: 安装核心依赖
echo "步骤 1: 安装核心依赖..."
source venv/bin/activate

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
echo ""

# 步骤 2: 使用不同端口启动数据库
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

echo "✅ 数据库容器已启动（端口 5433）"
echo ""

# 步骤 3: 更新数据库配置
echo "步骤 3: 更新数据库配置..."
if grep -q ":5432/" .env; then
    sed -i 's|postgresql://postgres:postgres123@localhost:5432/|postgresql://postgres:postgres123@localhost:5433/|' .env
    echo "✅ 数据库配置已更新为使用端口 5433"
else
    echo "ℹ️  数据库配置已是 5433 端口"
fi
echo ""

# 步骤 4: 等待数据库启动
echo "步骤 4: 等待数据库启动..."
sleep 10

# 测试数据库连接
if docker exec -it tnho-db psql -U postgres -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ 数据库连接测试成功"
else
    echo "⚠️  数据库连接测试失败，请检查日志"
    docker logs tnho-db | tail -20
fi
echo ""

# 步骤 5: 初始化数据库
echo "步骤 5: 初始化数据库..."
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('✅ 数据库初始化完成')
" 2>/dev/null || echo "ℹ️  数据库可能已初始化"
echo ""

# 步骤 6: 启动应用
echo "步骤 6: 启动应用..."
pkill -f uvicorn || true
mkdir -p logs

nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &
APP_PID=$!

echo "✅ 应用已启动，PID: $APP_PID"
echo ""

# 步骤 7: 等待服务启动
echo "步骤 7: 等待服务启动..."
sleep 10

# 步骤 8: 测试服务
echo "步骤 8: 测试服务..."
if curl -f http://localhost:8000/health; then
    echo ""
    echo "=========================================="
    echo "✅ 修复成功！服务正常运行"
    echo "=========================================="
    echo ""
    echo "访问地址："
    echo "  API 文档: http://tnho-fasteners.com/docs"
    echo "  健康检查: http://tnho-fasteners.com/health"
    echo "  本地访问: http://localhost:8000/health"
    echo ""
    echo "常用命令："
    echo "  查看日志: tail -f $PROJECT_DIR/logs/app.log"
    echo "  重启服务: pkill -f uvicorn; cd $PROJECT_DIR; nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &"
    echo "  停止服务: pkill -f uvicorn"
    echo "  数据库状态: docker ps | grep tnho-db"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 服务启动失败"
    echo "=========================================="
    echo ""
    echo "查看日志："
    echo "  tail -n 50 $PROJECT_DIR/logs/app.log"
    echo ""
    echo "数据库日志："
    echo "  docker logs tnho-db"
    echo ""
    echo "手动启动测试："
    echo "  cd $PROJECT_DIR"
    echo "  source venv/bin/activate"
    echo "  venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000"
    echo ""
fi
