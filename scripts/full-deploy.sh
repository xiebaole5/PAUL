#!/bin/bash

# 天虹紧固件视频API - 本地一键部署脚本
# 用法：在本地执行 ./scripts/full-deploy.sh

set -e  # 遇到错误立即退出

# 配置
SERVER="root@47.110.72.148"
PROJECT_DIR="/root/tnho-video-api"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "====================================="
echo "天虹紧固件视频API - 一键部署"
echo "====================================="
echo ""

# 检查SSH连接
print_step "检查SSH连接..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$SERVER" "echo 'SSH连接成功'" 2>/dev/null; then
    print_warn "SSH密钥认证失败，需要输入密码..."
fi

# 步骤1: 同步代码到服务器
print_step "步骤 1/3: 同步代码到服务器..."
rsync -avz --progress \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='*.log' \
  --exclude='tests' \
  --exclude='docs' \
  src/ \
  config/ \
  scripts/ \
  docker-compose.yml \
  Dockerfile \
  requirements.txt \
  "$SERVER:$PROJECT_DIR/"

print_success "代码同步完成"

# 步骤2: 上传并执行服务器端部署脚本
print_step "步骤 2/3: 上传自动化部署脚本..."
cat > /tmp/auto-deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash

set -e

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1" | tee -a "$LOG_FILE"
}

echo "=====================================" | tee -a "$LOG_FILE"
echo "部署时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"

cd "$PROJECT_DIR" || exit 1

# 检查并创建必要的目录和文件
if [ ! -d "src/llm" ]; then
    mkdir -p src/llm
fi

if [ ! -f "src/llm/__init__.py" ]; then
    cat > src/llm/__init__.py << 'EOF'
from .volcano_responses_llm import VolcanoResponsesLLM
__all__ = ['VolcanoResponsesLLM']
EOF
fi

# 停止并删除旧容器
print_step "停止旧容器..."
docker-compose down || true
docker stop tnho-video-api || true
docker rm tnho-video-api || true

# 清理未使用的镜像
print_step "清理Docker资源..."
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
    echo "✗ 容器启动失败" | tee -a "$LOG_FILE"
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
    echo "API健康检查失败" | tee -a "$LOG_FILE"
    docker-compose logs --tail=30
fi

# 显示最近的日志
print_step "最近的容器日志："
docker-compose logs --tail=20

echo ""
print_info "====================================="
print_info "部署完成！"
print_info "====================================="
print_info "API地址: http://47.110.72.148:8080"
print_info "健康检查: http://47.110.72.148:8080/health"
print_info "====================================="
DEPLOY_SCRIPT

chmod +x /tmp/auto-deploy.sh
scp /tmp/auto-deploy.sh "$SERVER:$PROJECT_DIR/scripts/auto-deploy.sh"
rm /tmp/auto-deploy.sh

print_success "部署脚本上传完成"

# 步骤3: 在服务器上执行部署
print_step "步骤 3/3: 在服务器上执行部署..."
ssh "$SERVER" "cd $PROJECT_DIR && chmod +x scripts/auto-deploy.sh && bash scripts/auto-deploy.sh"

echo ""
print_success "====================================="
print_success "全部操作完成！"
print_success "====================================="
print_info "您现在可以访问："
print_info "  - API地址: http://47.110.72.148:8080"
print_info "  - 健康检查: http://47.110.72.148:8080/health"
print_info ""
print_info "查看实时日志:"
echo "  ssh $SERVER 'cd $PROJECT_DIR && docker-compose logs -f'"
print_success "====================================="
