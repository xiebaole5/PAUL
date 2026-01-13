#!/bin/bash

# 天虹紧固件视频生成 Agent 修复脚本
# 修复 agent.py 导入问题并重新部署服务

set -e

echo "========================================="
echo "开始修复天虹紧固件视频生成 Agent"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/root/tnho-video-generator"
cd "$PROJECT_DIR" || { echo -e "${RED}错误：无法进入项目目录 $PROJECT_DIR${NC}"; exit 1; }

echo -e "${GREEN}步骤 1：检查 Dockerfile 配置${NC}"
if ! grep -q "PYTHONPATH=/app:/app/src" Dockerfile; then
    echo -e "${YELLOW}修复 Dockerfile 中的 PYTHONPATH 配置...${NC}"
    sed -i 's|COZE_WORKSPACE_PATH=/app$|COZE_WORKSPACE_PATH=/app \\\n    PYTHONPATH=/app:/app/src|' Dockerfile
    echo -e "${GREEN}✓ Dockerfile 已更新${NC}"
else
    echo -e "${GREEN}✓ Dockerfile 配置正确${NC}"
fi

echo ""
echo -e "${GREEN}步骤 2：停止现有容器${NC}"
docker compose down || { echo -e "${YELLOW}没有运行中的容器${NC}"; }

echo ""
echo -e "${GREEN}步骤 3：重新构建镜像${NC}"
docker compose build --no-cache

echo ""
echo -e "${GREEN}步骤 4：启动服务${NC}"
docker compose up -d

echo ""
echo -e "${GREEN}步骤 5：等待服务启动（30秒）${NC}"
sleep 30

echo ""
echo -e "${GREEN}步骤 6：检查容器状态${NC}"
docker compose ps

echo ""
echo -e "${GREEN}步骤 7：检查服务健康状态${NC}"
for i in {1..10}; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 服务启动成功！${NC}"
        break
    else
        echo -e "${YELLOW}等待服务启动... ($i/10)${NC}"
        sleep 3
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}✗ 服务启动失败${NC}"
        echo ""
        echo -e "${YELLOW}查看日志：${NC}"
        docker compose logs --tail=50
        exit 1
    fi
done

echo ""
echo -e "${GREEN}步骤 8：查看容器日志${NC}"
docker compose logs --tail=20

echo ""
echo "========================================="
echo -e "${GREEN}修复完成！服务已成功启动${NC}"
echo "========================================="
echo ""
echo "服务地址："
echo "  - API: http://47.110.72.148:8000"
echo "  - Health: http://47.110.72.148:8000/health"
echo "  - Nginx: http://47.110.72.148"
echo ""
echo "常用命令："
echo "  - 查看日志: docker compose logs -f"
echo "  - 重启服务: docker compose restart"
echo "  - 停止服务: docker compose down"
