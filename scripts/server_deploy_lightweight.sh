#!/bin/bash
# TNHO 视频生成服务 - 轻量部署脚本
# 在服务器 (47.110.72.148) 上执行此脚本
# 适用于低配置服务器：数据库用 Docker，应用直接用 Python 运行

set -e

echo "=========================================="
echo "TNHO 视频生成服务 - 轻量部署"
echo "=========================================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="/root/tnho-video"

# 步骤 1: 克隆或更新代码
echo "步骤 1: 检查代码..."
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "代码已存在，跳过克隆"
    cd "$PROJECT_DIR"
else
    echo "从 GitHub 克隆代码..."
    cd /root
    rm -rf tnho-video
    git clone https://github.com/xiebaole5/PAUL.git tnho-video
    cd tnho-project
fi

# 步骤 2: 停止现有服务
echo "步骤 2: 停止现有服务..."
pkill -f "uvicorn" || true
docker-compose down 2>/dev/null || true
cd "$PROJECT_DIR"

# 步骤 3: 安装系统依赖
echo "步骤 3: 安装系统依赖..."
apt-get update -qq
apt-get install -y python3-venv python3-dev libpq-dev ffmpeg postgresql-client 2>/dev/null || {
    echo "部分包已安装或安装失败，继续..."
}

# 步骤 4: 创建虚拟环境
echo "步骤 4: 创建 Python 虚拟环境..."
if [ -d "venv" ]; then
    echo "虚拟环境已存在"
else
    python3 -m venv venv
    echo "虚拟环境创建成功"
fi

# 步骤 5: 升级 pip
echo "步骤 5: 升级 pip..."
source venv/bin/activate
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ -q

# 步骤 6: 安装 Python 依赖
echo "步骤 6: 安装 Python 依赖包..."
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

# 步骤 7: 检查并配置 .env 文件
echo "步骤 7: 配置环境变量..."
if [ ! -f ".env" ]; then
    echo "创建 .env 文件..."
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
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5432/tnho_video

# 应用配置
APP_HOST=0.0.0.0
APP_PORT=8000
LOG_LEVEL=info
EOF

    echo "⚠️  .env 文件已创建，请修改以下配置："
    echo "   - S3_ACCESS_KEY_ID"
    echo "   - S3_SECRET_ACCESS_KEY"
    echo "   - S3_BUCKET"
    echo ""
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "部署已取消"
        exit 0
    fi
fi

# 步骤 8: 启动数据库容器
echo "步骤 8: 启动数据库容器..."
if ! docker ps | grep -q "tnho-db"; then
    echo "启动 PostgreSQL 容器..."
    docker run -d \
        --name tnho-db \
        -e POSTGRES_DB=tnho_video \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres123 \
        -p 5432:5432 \
        postgres:15-alpine

    echo "等待数据库启动..."
    sleep 10
else
    echo "数据库容器已运行"
fi

# 步骤 9: 初始化数据库
echo "步骤 9: 初始化数据库表..."
sleep 5
python3 -m venv venv
source venv/bin/activate
python3 -c "
import sys
sys.path.insert(0, '.')
from src.storage.database.init_db import init_db
init_db()
print('数据库初始化完成')
" 2>/dev/null || echo "数据库初始化已跳过（可能已存在）"

# 步骤 10: 启动应用服务
echo "步骤 10: 启动应用服务..."
pkill -f "uvicorn" || true
nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &
APP_PID=$!
echo "应用已启动，PID: $APP_PID"

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 步骤 11: 检查服务状态
echo "步骤 11: 检查服务状态..."
if curl -f http://localhost:8000/health; then
    echo ""
    echo "✅ 服务启动成功！"
else
    echo ""
    echo "❌ 服务启动失败，查看日志："
    tail -n 50 logs/app.log
    exit 1
fi

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "访问地址："
echo "  API 文档: http://tnho-fasteners.com/docs"
echo "  健康检查: http://tnho-fasteners.com/health"
echo "  本地访问: http://47.110.72.148:8000/health"
echo ""
echo "常用命令："
echo "  查看日志: tail -f logs/app.log"
echo "  重启服务: pkill -f uvicorn; cd $PROJECT_DIR; nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &"
echo "  停止服务: pkill -f uvicorn"
echo "  数据库状态: docker ps | grep tnho-db"
echo "  更新代码: cd $PROJECT_DIR; git pull; source venv/bin/activate; pip install -r requirements.txt; pkill -f uvicorn; nohup venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000 > logs/app.log 2>&1 &"
echo ""
