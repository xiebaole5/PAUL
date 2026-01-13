#!/bin/bash

# 天虹紧固件视频API - 服务验证和测试脚本

echo "====================================="
echo "服务验证和测试"
echo "====================================="
echo ""

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# 1. 检查容器状态
echo "[TEST] 1. 检查容器状态..."
if docker ps | grep -q tnho-video-api; then
    print_success "容器运行正常"
    docker ps | grep tnho-video-api
else
    print_error "容器未运行"
    exit 1
fi
echo ""

# 2. 测试根路径
echo "[TEST] 2. 测试根路径 /"
ROOT_RESPONSE=$(curl -s http://localhost:8000/)
if [ $? -eq 0 ]; then
    print_success "根路径访问成功"
    echo "响应: $ROOT_RESPONSE"
else
    print_error "根路径访问失败"
fi
echo ""

# 3. 测试健康检查
echo "[TEST] 3. 测试健康检查 /health"
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
if [ $? -eq 0 ]; then
    print_success "健康检查通过"
    echo "响应: $HEALTH_RESPONSE"
else
    print_error "健康检查失败"
fi
echo ""

# 4. 测试外部访问
echo "[TEST] 4. 测试外部访问（公网IP）"
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "47.110.72.148")
print_info "公网IP: $EXTERNAL_IP"
echo "请尝试在浏览器访问:"
echo "  - http://47.110.72.148:8000"
echo "  - http://47.110.72.148:8000/health"
echo ""

# 5. 显示最近的日志
echo "[TEST] 5. 最近的容器日志"
echo "====================================="
docker-compose logs --tail=10
echo ""

echo "====================================="
echo "验证完成！"
echo "====================================="
echo ""
print_info "常用命令:"
echo "  查看实时日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo "  进入容器: docker exec -it tnho-video-api /bin/bash"
echo ""
print_info "API 文档 (如果已启用):"
echo "  http://47.110.72.148:8000/docs"
echo "  http://47.110.72.148:8000/redoc"
echo ""
