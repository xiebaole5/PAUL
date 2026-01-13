#!/bin/bash

# 天虹紧固件视频生成服务 - 一键部署脚本
# 用途：更新服务器代码并重启服务

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在正确的目录
if [ ! -f "docker-compose.yml" ]; then
    print_error "请在项目根目录（包含 docker-compose.yml）运行此脚本"
    exit 1
fi

print_info "开始部署流程..."

# 1. 备份当前代码
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
print_info "备份当前代码到 $BACKUP_DIR ..."
mkdir -p $BACKUP_DIR
cp -r src $BACKUP_DIR/
cp -r config $BACKUP_DIR/
print_info "备份完成"

# 2. 检查必需的文件
print_info "检查必需的文件..."
required_files=(
    "src/llm/__init__.py"
    "src/llm/volcano_responses_llm.py"
    "src/agents/agent.py"
    "config/agent_llm_config.json"
    "src/tools/video_generation_tool.py"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "缺少文件: $file"
        print_warn "请确保所有更新文件都已上传"
        exit 1
    fi
done
print_info "所有必需文件检查通过"

# 3. 停止旧容器
print_info "停止旧容器..."
docker-compose down

# 4. 重新构建镜像
print_info "重新构建 Docker 镜像（这可能需要几分钟）..."
docker-compose build --no-cache api

# 5. 启动服务
print_info "启动服务..."
docker-compose up -d

# 6. 等待服务启动
print_info "等待服务启动（约30秒）..."
sleep 30

# 7. 健康检查
print_info "执行健康检查..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_info "健康检查通过 ✓"
else
    print_error "健康检查失败 ✗"
    print_warn "查看日志：docker-compose logs api"
    exit 1
fi

# 8. 测试 API
print_info "测试 API 接口..."
response=$(curl -s -X POST http://localhost/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{"product_name":"测试","theme":"品质保证","duration":5,"type":"script"}' | jq -r '.success')

if [ "$response" = "true" ]; then
    print_info "API 测试通过 ✓"
else
    print_warn "API 测试可能有问题，请检查：docker-compose logs api"
fi

# 9. 显示服务状态
print_info "服务状态："
docker-compose ps

# 10. 完成
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}     部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
print_info "常用命令："
echo "  查看日志：docker-compose logs -f api"
echo "  重启服务：docker-compose restart"
echo "  停止服务：docker-compose down"
echo "  进入容器：docker exec -it tnho-video-api /bin/bash"
echo ""
print_info "API 地址："
echo "  HTTP:  http://47.110.72.148"
echo "  HTTPS: https://tnho-fasteners.com"
echo ""
