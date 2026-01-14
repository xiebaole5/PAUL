#!/bin/bash
# 天虹紧固件视频生成服务 - 服务器部署脚本
# 用途：从 GitHub 克隆代码并部署到服务器

set -e  # 遇到错误立即退出

echo "=========================================="
echo "天虹紧固件视频生成服务 - 开始部署"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_DIR="/root/PAUL"
GITHUB_REPO="https://github.com/xiebaole5/PAUL.git"
VENV_DIR="${PROJECT_DIR}/venv"

echo ""
echo -e "${YELLOW}[步骤 1/8]${NC} 检查系统环境"
echo "----------------------------------------"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误：请使用 root 用户执行此脚本${NC}"
    exit 1
fi

# 检查 Python 版本
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}错误：未找到 Python3${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo -e "${GREEN}✓${NC} Python 版本: ${PYTHON_VERSION}"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误：未找到 Docker${NC}"
    echo "请先安装 Docker：curl -fsSL https://get.docker.com | sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker 已安装"

# 检查 Nginx
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}警告：未找到 Nginx，将跳过 Nginx 配置${NC}"
else
    echo -e "${GREEN}✓${NC} Nginx 已安装"
fi

echo ""
echo -e "${YELLOW}[步骤 2/8]${NC} 克隆代码仓库"
echo "----------------------------------------"

# 检查是否已存在项目目录
if [ -d "${PROJECT_DIR}" ]; then
    echo -e "${YELLOW}检测到项目目录已存在，正在备份并重新克隆...${NC}"
    BACKUP_DIR="${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    mv "${PROJECT_DIR}" "${BACKUP_DIR}"
    echo -e "${GREEN}✓${NC} 已备份到 ${BACKUP_DIR}"
fi

git clone "${GITHUB_REPO}" "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

echo -e "${GREEN}✓${NC} 代码克隆完成"

echo ""
echo -e "${YELLOW}[步骤 3/8]${NC} 创建虚拟环境"
echo "----------------------------------------"

if [ -d "${VENV_DIR}" ]; then
    echo -e "${YELLOW}虚拟环境已存在，正在删除...${NC}"
    rm -rf "${VENV_DIR}"
fi

python3 -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"

echo -e "${GREEN}✓${NC} 虚拟环境创建完成"

echo ""
echo -e "${YELLOW}[步骤 4/8]${NC} 安装 Python 依赖"
echo "----------------------------------------"

# 配置国内镜像源
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/

# 升级 pip
pip install --upgrade pip

# 安装依赖
pip install -r requirements.txt

echo -e "${GREEN}✓${NC} Python 依赖安装完成"

echo ""
echo -e "${YELLOW}[步骤 5/8]${NC} 配置环境变量"
echo "----------------------------------------"

if [ ! -f "${PROJECT_DIR}/.env" ]; then
    cat > "${PROJECT_DIR}/.env" << 'EOF'
# 数据库配置（Docker 容器）
PGDATABASE_URL=postgresql://postgres:postgres123@localhost:5432/tnho_video

# 对象存储配置（需要根据实际情况填写）
S3_ENDPOINT=https://s3-cn-north-4.volces.com
S3_ACCESS_KEY_ID=your_access_key
S3_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your_bucket_name
S3_REGION=cn-north-4

# 外部访问 URL
EXTERNAL_BASE_URL=https://tnho-fasteners.com

# API 配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076

# 调试模式
DEBUG=False
EOF
    echo -e "${GREEN}✓${NC} 已创建 .env 文件（默认配置）"
    echo -e "${YELLOW}请根据实际情况修改 ${PROJECT_DIR}/.env 文件${NC}"
else
    echo -e "${GREEN}✓${NC} .env 文件已存在，跳过创建"
fi

echo ""
echo -e "${YELLOW}[步骤 6/8]${NC} 启动 PostgreSQL 数据库"
echo "----------------------------------------"

# 检查容器是否已存在
if docker ps -a --format '{{.Names}}' | grep -q "^tnho-postgres$"; then
    echo -e "${YELLOW}检测到 PostgreSQL 容器已存在${NC}"
    read -p "是否重新创建容器？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker stop tnho-postgres 2>/dev/null || true
        docker rm tnho-postgres 2>/dev/null || true
    else
        echo -e "${GREEN}✓${NC} 使用现有 PostgreSQL 容器"
        POSTGRES_RUNNING=false
    fi
fi

if ! docker ps --format '{{.Names}}' | grep -q "^tnho-postgres$"; then
    echo "正在启动 PostgreSQL 容器..."
    docker run -d \
        --name tnho-postgres \
        -e POSTGRES_DB=tnho_video \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres123 \
        -p 5432:5432 \
        -v tnho-postgres-data:/var/lib/postgresql/data \
        --restart unless-stopped \
        postgres:15

    echo -e "${YELLOW}等待 PostgreSQL 启动...${NC}"
    sleep 10

    # 检查容器是否运行
    if docker ps --format '{{.Names}}' | grep -q "^tnho-postgres$"; then
        echo -e "${GREEN}✓${NC} PostgreSQL 启动成功"
    else
        echo -e "${RED}✗${NC} PostgreSQL 启动失败"
        docker logs tnho-postgres
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} PostgreSQL 已在运行"
fi

echo ""
echo -e "${YELLOW}[步骤 7/8]${NC} 初始化数据库表结构"
echo "----------------------------------------"

cd "${PROJECT_DIR}"
source "${VENV_DIR}/bin/activate"

# 初始化数据库表
python -c "
import asyncio
from src.storage.database.db import get_engine
from src.storage.database.models import Base

engine = get_engine()
Base.metadata.create_all(bind=engine)
print('数据库表创建成功')
"

echo -e "${GREEN}✓${NC} 数据库表结构初始化完成"

echo ""
echo -e "${YELLOW}[步骤 8/8]${NC} 创建 systemd 服务"
echo "----------------------------------------"

# 创建 systemd 服务文件
cat > /etc/systemd/system/tnho-api.service << 'EOF'
[Unit]
Description=天虹紧固件视频生成 API 服务
After=network.target tnho-postgres.service docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/PAUL
Environment="PATH=/root/PAUL/venv/bin"
ExecStart=/root/PAUL/venv/bin/python app.py
Restart=always
RestartSec=10

# 日志配置
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tnho-api

[Install]
WantedBy=multi-user.target
EOF

# 重载 systemd
systemctl daemon-reload

echo -e "${GREEN}✓${NC} systemd 服务创建完成"

echo ""
echo "=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "=========================================="
echo ""
echo "接下来的步骤："
echo ""
echo "1. 编辑环境变量文件："
echo "   vim ${PROJECT_DIR}/.env"
echo ""
echo "2. 启动服务："
echo "   systemctl start tnho-api"
echo ""
echo "3. 查看服务状态："
echo "   systemctl status tnho-api"
echo ""
echo "4. 查看日志："
echo "   journalctl -u tnho-api -f"
echo ""
echo "5. 配置 Nginx（如需要）："
echo "   vim /etc/nginx/conf.d/tnho-api.conf"
echo "   nginx -t && systemctl reload nginx"
echo ""
echo -e "${YELLOW}注意：请确保已配置正确的 S3 对象存储密钥${NC}"
echo ""
