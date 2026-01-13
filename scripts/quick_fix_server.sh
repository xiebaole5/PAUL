#!/bin/bash
# 天虹紧固件视频生成服务 - 服务器一键修复脚本
# 解决虚拟环境、依赖、数据库初始化等所有问题

set -e  # 遇到错误立即退出

echo "=========================================="
echo "天虹视频生成服务 - 一键修复脚本"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/root/tnho-video"
cd $PROJECT_DIR

echo -e "${YELLOW}[1/8] 检查项目文件完整性...${NC}"

# 检查关键文件
MISSING_FILES=0

if [ ! -f "app.py" ]; then
    echo -e "${RED}❌ 缺失 app.py${NC}"
    MISSING_FILES=1
else
    echo -e "${GREEN}✅ app.py 存在${NC}"
fi

if [ ! -f "src/storage/database/init_db.py" ]; then
    echo -e "${RED}❌ 缺失 src/storage/database/init_db.py${NC}"
    MISSING_FILES=1
else
    echo -e "${GREEN}✅ init_db.py 存在${NC}"
fi

if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}❌ 缺失 requirements.txt${NC}"
    MISSING_FILES=1
else
    echo -e "${GREEN}✅ requirements.txt 存在${NC}"
fi

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 文件不存在，将创建默认配置${NC}"
fi

if [ $MISSING_FILES -eq 1 ]; then
    echo -e "${RED}❌ 项目文件不完整，请重新克隆 GitHub 仓库${NC}"
    echo -e "执行命令: cd /root && rm -rf tnho-video && git clone https://github.com/xiebaole5/PAUL.git tnho-video"
    exit 1
fi

echo -e "${GREEN}✅ 项目文件检查通过${NC}"

echo -e "${YELLOW}[2/8] 创建 Python 虚拟环境...${NC}"

if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
    echo -e "${GREEN}✅ 虚拟环境创建成功${NC}"
else
    echo -e "${GREEN}✅ 虚拟环境已存在${NC}"
fi

echo -e "${YELLOW}[3/8] 激活虚拟环境并升级 pip...${NC}"

source venv/bin/activate
pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
echo -e "${GREEN}✅ pip 升级成功${NC}"

echo -e "${YELLOW}[4/8] 安装项目依赖...${NC}"

# 使用阿里云镜像安装依赖
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
echo -e "${GREEN}✅ 依赖安装成功${NC}"

echo -e "${YELLOW}[5/8] 检查 .env 配置文件...${NC}"

if [ ! -f ".env" ]; then
    echo "创建默认 .env 配置文件..."
    cat > .env << 'EOF'
# 火山方舟 API 配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_ENDPOINT_URL=https://ark.cn-beijing.volces.com/api/v3

# 数据库配置（使用 Docker 容器）
PGDATABASE_URL=postgresql://postgres:postgres@localhost:5433/tnho_video

# 对象存储配置（需要根据实际情况修改）
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
    echo -e "${YELLOW}⚠️  已创建默认 .env 文件，请修改对象存储配置${NC}"
else
    echo -e "${GREEN}✅ .env 文件已存在${NC}"
fi

echo -e "${YELLOW}[6/8] 检查并启动 PostgreSQL 数据库容器...${NC}"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker 未安装，跳过数据库容器启动${NC}"
    echo "请手动安装 Docker：curl -fsSL https://get.docker.com | sh"
else
    # 检查 PostgreSQL 容器是否运行
    if ! docker ps | grep -q tnho-postgres; then
        echo "启动 PostgreSQL 容器..."
        docker stop tnho-postgres 2>/dev/null || true
        docker rm tnho-postgres 2>/dev/null || true

        docker run -d \
            --name tnho-postgres \
            -e POSTGRES_PASSWORD=postgres \
            -e POSTGRES_DB=tnho_video \
            -p 5433:5432 \
            postgres:15-alpine

        echo -e "${GREEN}✅ PostgreSQL 容器启动成功${NC}"
        echo "等待数据库初始化..."
        sleep 5
    else
        echo -e "${GREEN}✅ PostgreSQL 容器已运行${NC}"
    fi
fi

echo -e "${YELLOW}[7/8] 初始化数据库表结构...${NC}"

# 初始化数据库（使用 Python 路径）
python3 -c "
import sys
import os
sys.path.insert(0, '${PROJECT_DIR}')
os.environ['COZE_WORKSPACE_PATH'] = '${PROJECT_DIR}'
from src.storage.database.init_db import init_db
init_db()
print('数据库初始化完成')
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 数据库初始化成功${NC}"
else
    echo -e "${RED}❌ 数据库初始化失败${NC}"
    exit 1
fi

echo -e "${YELLOW}[8/8] 启动应用服务...${NC}"

# 停止旧服务
pkill -f "uvicorn app:app" || true
sleep 2

# 创建日志目录
mkdir -p logs

# 启动服务
nohup venv/bin/python -m uvicorn app:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --log-level info \
    > logs/app.log 2>&1 &

APP_PID=$!
echo "应用 PID: $APP_PID"

# 等待服务启动
echo "等待服务启动..."
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 服务启动成功！${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ 服务启动失败，查看日志：${NC}"
        tail -n 50 logs/app.log
        exit 1
    fi
    sleep 2
done

# 测试健康检查
HEALTH_STATUS=$(curl -s http://localhost:8000/health)
echo -e "${GREEN}健康检查结果：${NC}"
echo $HEALTH_STATUS

# 测试 API 文档
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ 修复完成！${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "服务访问地址："
echo "  - 本地: http://localhost:8000"
echo "  - 公网: http://47.110.72.148:8000"
echo "  - 域名: http://tnho-fasteners.com"
echo ""
echo "API 文档地址："
echo "  - Swagger UI: http://tnho-fasteners.com/docs"
echo "  - ReDoc: http://tnho-fasteners.com/redoc"
echo ""
echo "常用命令："
echo "  - 查看日志: tail -f logs/app.log"
echo "  - 停止服务: pkill -f 'uvicorn app:app'"
echo "  - 重启服务: ./scripts/quick_fix_server.sh"
echo "  - 进入虚拟环境: source venv/bin/activate"
echo ""
echo "如果服务无法启动，请查看日志文件：logs/app.log"
