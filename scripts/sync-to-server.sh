#!/bin/bash

# 代码同步脚本 - 从本地同步到服务器
# 用法：./sync-to-server.sh

SERVER="root@47.110.72.148"
PROJECT_DIR="/root/tnho-video-api"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info "开始同步代码到 $SERVER ..."

# 同步文件
print_info "同步 src/llm/ ..."
rsync -avz --progress \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  src/llm/ \
  $SERVER:$PROJECT_DIR/src/llm/

print_info "同步 src/agents/agent.py ..."
rsync -avz --progress \
  src/agents/agent.py \
  $SERVER:$PROJECT_DIR/src/agents/

print_info "同步 config/agent_llm_config.json ..."
rsync -avz --progress \
  config/agent_llm_config.json \
  $SERVER:$PROJECT_DIR/config/

print_info "同步 src/tools/video_generation_tool.py ..."
rsync -avz --progress \
  src/tools/video_generation_tool.py \
  $SERVER:$PROJECT_DIR/src/tools/

print_info "同步部署脚本 ..."
rsync -avz --progress \
  scripts/deploy.sh \
  $SERVER:$PROJECT_DIR/scripts/

print_info "同步 Docker 配置文件 ..."
rsync -avz --progress \
  docker-compose.yml \
  Dockerfile \
  $SERVER:$PROJECT_DIR/

echo ""
print_info "代码同步完成！"
print_info "接下来在服务器上执行："
echo "  1. ssh $SERVER"
echo "  2. cd $PROJECT_DIR"
echo "  3. chmod +x scripts/deploy.sh"
echo "  4. ./scripts/deploy.sh"
