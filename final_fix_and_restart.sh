#!/bin/bash

# 最终修复脚本 - 修复 sys.path 并重启服务

set -e

echo "========================================="
echo "修复并重启天虹紧固件视频生成服务"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "步骤 1: 检查 app.py"
echo "-------------------------------------------"

# 检查 sys.path 设置
if grep -q "sys.path.insert.*workspace_path" src/api/app.py; then
    echo -e "${GREEN}✓ app.py sys.path 设置正确${NC}"
else
    echo -e "${YELLOW}需要更新 app.py${NC}"
    echo "请确保 app.py 中同时添加了 /app 和 /app/src 到 sys.path"
fi

echo ""
echo "步骤 2: 停止现有容器"
echo "-------------------------------------------"
docker-compose down

echo ""
echo "步骤 3: 重新构建镜像"
echo "-------------------------------------------"
docker-compose build --no-cache

echo ""
echo "步骤 4: 启动服务"
echo "-------------------------------------------"
docker-compose up -d

echo ""
echo "步骤 5: 等待服务启动（30秒）"
echo "-------------------------------------------"
sleep 30

echo ""
echo "步骤 6: 检查容器状态"
echo "-------------------------------------------"
docker-compose ps

echo ""
echo "步骤 7: 查看日志（最后 50 行）"
echo "-------------------------------------------"
docker-compose logs --tail=50

echo ""
echo "步骤 8: 测试健康检查"
echo "-------------------------------------------"
if curl -f http://localhost:8000/health; then
    echo -e "${GREEN}✓ 服务启动成功！${NC}"
    echo ""
    echo "服务地址："
    echo "  - API: http://47.110.72.148:8000"
    echo "  - Health: http://47.110.72.148:8000/health"
    echo "  - Nginx: http://47.110.72.148"
else
    echo -e "${RED}✗ 服务启动失败${NC}"
    echo ""
    echo "请查看完整日志："
    echo "  docker-compose logs -f tnho-video-api"
fi

echo ""
echo "========================================="
echo -e "${GREEN}修复完成${NC}"
echo "========================================="
