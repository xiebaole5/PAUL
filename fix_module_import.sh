#!/bin/bash

echo "=== 天虹视频生成服务 - 模块导入错误修复 ==="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 停止所有容器
echo -e "${GREEN}[1/5]${NC} 停止所有容器..."
docker-compose down

# 重新构建镜像（不带缓存，确保修复生效）
echo -e "${GREEN}[2/5]${NC} 重新构建 Docker 镜像..."
docker-compose build --no-cache

if [ $? -ne 0 ]; then
    echo -e "${RED}镜像构建失败！${NC}"
    exit 1
fi

# 启动容器
echo -e "${GREEN}[3/5]${NC} 启动容器..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}容器启动失败！${NC}"
    exit 1
fi

# 等待容器启动
echo -e "${GREEN}[4/5]${NC} 等待容器启动（30秒）..."
sleep 30

# 检查容器状态
echo -e "${GREEN}[5/5]${NC} 检查容器状态..."
docker-compose ps

echo ""
echo "等待 10 秒后检查健康状态..."
sleep 10

# 测试健康检查
echo ""
echo "=== 测试健康检查 ==="
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>&1)

if [ "$HEALTH_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ 健康检查通过 (HTTP 200)${NC}"
    curl -s http://localhost:8000/health | jq .
    echo ""
    echo -e "${GREEN}=== 修复成功！===${NC}"
    echo ""
    echo "API 文档访问地址:"
    echo "  - 内部: http://localhost:8000/docs"
    echo "  - 外部: http://47.110.72.148/docs"
    echo ""
    echo "健康检查地址:"
    echo "  - 内部: http://localhost:8000/health"
    echo "  - 外部: http://47.110.72.148/health"
else
    echo -e "${RED}✗ 健康检查失败 (HTTP $HEALTH_STATUS)${NC}"
    echo ""
    echo "查看最新日志："
    echo "  docker-compose logs --tail=50 api"
    echo ""
    echo "查看实时日志："
    echo "  docker-compose logs -f api"
    exit 1
fi
