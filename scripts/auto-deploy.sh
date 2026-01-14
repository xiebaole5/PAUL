#!/bin/bash

# 天虹紧固件视频API - 服务器端自动化部署脚本
# 用法：在服务器上直接执行 ./scripts/auto-deploy.sh

set -e  # 遇到错误立即退出

# 配置
PROJECT_DIR="/root/tnho-video-api"
LOG_FILE="${PROJECT_DIR}/deploy.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1" | tee -a "$LOG_FILE"
}

# 记录开始时间
echo "=====================================" | tee -a "$LOG_FILE"
echo "部署时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"

# 进入项目目录
print_step "切换到项目目录: $PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

# 检查必要文件是否存在
print_step "检查关键文件..."

check_and_create_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        print_warn "文件不存在: $file，将创建..."
        return 1
    else
        print_info "文件存在: $file"
        return 0
    fi
}

# 检查并创建 src/llm 目录和文件
if [ ! -d "src/llm" ]; then
    print_warn "创建 src/llm 目录..."
    mkdir -p src/llm
fi

# 如果文件不存在，创建它们
if ! check_and_create_file "src/llm/__init__.py"; then
    print_info "创建 src/llm/__init__.py"
    cat > src/llm/__init__.py << 'EOF'
"""
火山方舟 LLM 模块
"""
from .volcano_responses_llm import VolcanoResponsesLLM

__all__ = ['VolcanoResponsesLLM']
EOF
fi

# 停止并删除旧容器
print_step "停止旧容器..."
docker-compose down || true
docker stop tnho-video-api || true
docker rm tnho-video-api || true

# 清理未使用的镜像（可选）
print_step "清理未使用的Docker资源..."
docker image prune -f || true

# 构建新镜像
print_step "构建Docker镜像..."
docker-compose build --no-cache

# 启动服务
print_step "启动服务..."
docker-compose up -d

# 等待服务启动
print_step "等待服务启动（15秒）..."
sleep 15

# 检查容器状态
print_step "检查容器状态..."
if docker ps | grep -q tnho-video-api; then
    print_info "✓ 容器运行正常"
else
    print_error "✗ 容器启动失败"
    docker-compose logs --tail=50
    exit 1
fi

# 测试API
print_step "测试API健康检查..."
sleep 5

API_URL="http://localhost:8080"
if curl -s "${API_URL}/health" > /dev/null 2>&1; then
    print_info "✓ API健康检查通过"
else
    print_warn "API健康检查失败，查看日志..."
    docker-compose logs --tail=30
fi

# 显示容器日志（最近20行）
print_step "最近的容器日志："
docker-compose logs --tail=20

# 显示访问信息
echo ""
print_info "====================================="
print_info "部署完成！"
print_info "====================================="
print_info "API地址: http://47.110.72.148:8080"
print_info "健康检查: http://47.110.72.148:8080/health"
print_info "查看日志: docker-compose logs -f"
print_info "停止服务: docker-compose down"
print_info "重启服务: docker-compose restart"
print_info "====================================="
echo ""
