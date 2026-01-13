#!/bin/bash

echo "=== 天虹视频生成服务 - 修复和重新部署脚本 ==="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：打印信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 1. 检查 .env 文件
print_info "检查配置文件..."
if [ ! -f .env ]; then
    print_warning ".env 文件不存在，创建默认配置..."
    cat > .env << 'EOF'
# 火山方舟 API 配置
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 数据库配置（可选，不配置将使用内存存储）
# PGDATABASE_URL=postgresql://user:password@localhost:5432/dbname

# 外部访问地址
EXTERNAL_BASE_URL=http://47.110.72.148
EOF
    print_info ".env 文件已创建，使用默认配置"
fi

# 2. 停止所有容器
print_info "停止所有容器..."
docker-compose down
print_info "容器已停止"

# 3. 清理旧镜像（可选）
print_warning "是否清理旧镜像？(y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_info "清理旧镜像..."
    docker-compose rm -f
fi

# 4. 重新构建镜像
print_info "重新构建 Docker 镜像..."
docker-compose build --no-cache

if [ $? -ne 0 ]; then
    print_error "镜像构建失败！"
    exit 1
fi

print_info "镜像构建成功"

# 5. 启动容器
print_info "启动容器..."
docker-compose up -d

if [ $? -ne 0 ]; then
    print_error "容器启动失败！"
    exit 1
fi

print_info "容器已启动"

# 6. 等待容器启动
print_info "等待容器启动（30秒）..."
sleep 30

# 7. 检查容器状态
print_info "检查容器状态..."
docker-compose ps

# 8. 查看容器日志
print_info "查看最新日志（最近 30 行）："
docker-compose logs --tail=30 tnho-video-api

# 9. 测试健康检查
print_info "测试健康检查接口..."
sleep 5
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>&1)

if [ "$HEALTH_CHECK" = "200" ]; then
    print_info "✓ 健康检查通过！"
    print_info "API 文档访问地址: http://47.110.72.148/docs"
    print_info "健康检查地址: http://47.110.72.148/health"
else
    print_error "✗ 健康检查失败（HTTP $HEALTH_CHECK）"
    print_error "请查看容器日志排查问题："
    print_error "  docker-compose logs -f tnho-video-api"
fi

echo ""
print_info "部署完成！"
print_info "如果服务未正常启动，请运行："
print_info "  bash debug_container.sh    # 查看详细诊断信息"
print_info "  docker-compose logs -f tnho-video-api  # 查看实时日志"
