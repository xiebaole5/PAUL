#!/bin/bash

# 天虹紧固件视频生成系统 - 自动化部署脚本
# 适用于阿里云 Ubuntu 22.04 LTS

set -e

echo "======================================"
echo "  天虹紧固件视频生成系统部署脚本"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 用户或 sudo 运行此脚本${NC}"
    exit 1
fi

# 检查操作系统
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}无法检测操作系统版本${NC}"
    exit 1
fi

source /etc/os-release
echo -e "${GREEN}检测到操作系统: $PRETTY_NAME${NC}"
echo ""

# 1. 安装 Docker
echo -e "${YELLOW}步骤 1/6: 安装 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "安装 Docker..."
    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 添加 Docker 官方 GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 添加 Docker APT 源
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动 Docker
    systemctl start docker
    systemctl enable docker

    echo -e "${GREEN}Docker 安装成功！${NC}"
else
    echo -e "${GREEN}Docker 已安装${NC}"
fi
echo ""

# 2. 安装 Docker Compose
echo -e "${YELLOW}步骤 2/6: 安装 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "安装 Docker Compose..."
    curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose 安装成功！${NC}"
else
    echo -e "${GREEN}Docker Compose 已安装${NC}"
fi
echo ""

# 3. 创建项目目录
echo -e "${YELLOW}步骤 3/6: 创建项目目录...${NC}"
PROJECT_DIR="/opt/tnho-video-generator"
mkdir -p $PROJECT_DIR
mkdir -p $PROJECT_DIR/nginx/logs
mkdir -p $PROJECT_DIR/assets/uploads
mkdir -p $PROJECT_DIR/logs
echo -e "${GREEN}项目目录创建成功: $PROJECT_DIR${NC}"
echo ""

# 4. 配置环境变量
echo -e "${YELLOW}步骤 4/6: 配置环境变量...${NC}"
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "请输入火山方舟 API Key:"
    read -p "ARK_API_KEY: " ARK_API_KEY
    echo "请输入火山方舟 Base URL (默认: https://ark.cn-beijing.volces.com/api/v3):"
    read -p "ARK_BASE_URL: " ARK_BASE_URL
    ARK_BASE_URL=${ARK_BASE_URL:-https://ark.cn-beijing.volces.com/api/v3}

    # 创建 .env 文件
    cat > $ENV_FILE << EOF
ARK_API_KEY=$ARK_API_KEY
ARK_BASE_URL=$ARK_BASE_URL
COZE_WORKSPACE_PATH=/app
API_PORT=8000
NGINX_PORT=80
LOG_LEVEL=INFO
EOF
    echo -e "${GREEN}环境变量配置成功！${NC}"
else
    echo -e "${GREEN}环境变量文件已存在，跳过配置${NC}"
fi
echo ""

# 5. 上传项目文件
echo -e "${YELLOW}步骤 5/6: 上传项目文件...${NC}"
echo "请确保以下文件已上传到 $PROJECT_DIR 目录:"
echo "  - Dockerfile"
echo "  - docker-compose.yml"
echo "  - requirements.txt"
echo "  - src/ (目录)"
echo "  - config/ (目录)"
echo "  - nginx/nginx.conf"
echo ""
read -p "文件是否已上传? (y/n): " uploaded
if [ "$uploaded" != "y" ]; then
    echo -e "${RED}请先上传项目文件后再运行此脚本${NC}"
    exit 1
fi
echo -e "${GREEN}项目文件检查完成${NC}"
echo ""

# 6. 启动服务
echo -e "${YELLOW}步骤 6/6: 启动服务...${NC}"
cd $PROJECT_DIR

# 停止旧容器
echo "停止旧容器..."
docker-compose down

# 构建镜像
echo "构建 Docker 镜像..."
docker-compose build

# 启动服务
echo "启动服务..."
docker-compose up -d

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 检查服务状态
echo ""
echo -e "${YELLOW}服务状态检查:${NC}"
docker-compose ps

# 测试 API
echo ""
echo -e "${YELLOW}测试 API 连接...${NC}"
sleep 5
if curl -s http://localhost/health | grep -q "ok"; then
    echo -e "${GREEN}API 服务运行正常！${NC}"
else
    echo -e "${RED}API 服务可能未正常启动，请检查日志${NC}"
    echo "查看日志命令: docker-compose logs -f"
fi

echo ""
echo "======================================"
echo -e "${GREEN}部署完成！${NC}"
echo "======================================"
echo ""
echo "服务访问地址:"
echo "  - API 服务: http://<服务器IP>:8000"
echo "  - Nginx 代理: http://<服务器IP>"
echo "  - 健康检查: http://<服务器IP>/health"
echo ""
echo "常用命令:"
echo "  - 查看日志: docker-compose logs -f"
echo "  - 停止服务: docker-compose stop"
echo "  - 重启服务: docker-compose restart"
echo "  - 查看状态: docker-compose ps"
echo ""
echo "下一步:"
echo "  1. 配置防火墙，开放 80 和 443 端口"
echo "  2. 配置域名和 SSL 证书（可选）"
echo "  3. 更新微信小程序的 API 地址"
echo ""
