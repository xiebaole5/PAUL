#!/bin/bash

# 天虹紧固件视频生成服务 - 完整部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================="
echo "天虹紧固件视频生成服务部署"
echo "========================================="
echo ""

# API Key 配置
API_KEY="e1533511-efae-4131-aea9-b573a1be4ecf"
BASE_URL="https://ark.cn-beijing.volces.com/api/v3"

echo -e "${BLUE}步骤 1: 配置 API Key${NC}"
echo "-------------------------------------------"

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
    echo "创建 .env 文件..."
    cat > .env << EOF
ARK_API_KEY=${API_KEY}
ARK_BASE_URL=${BASE_URL}
EXTERNAL_BASE_URL=https://tnho-fasteners.com
EOF
    echo -e "${GREEN}✓ .env 文件已创建${NC}"
else
    echo -e "${YELLOW}.env 文件已存在，更新 API Key...${NC}"
    sed -i "s/ARK_API_KEY=.*/ARK_API_KEY=${API_KEY}/" .env
    sed -i "s|ARK_BASE_URL=.*|ARK_BASE_URL=${BASE_URL}|" .env
    echo -e "${GREEN}✓ .env 文件已更新${NC}"
fi

echo ""
echo -e "${BLUE}步骤 2: 验证代码文件${NC}"
echo "-------------------------------------------"

# 检查 agent.py 导入语句
if grep -q "from storage.memory.memory_saver import" src/agents/agent.py; then
    echo -e "${GREEN}✓ agent.py 导入语句正确${NC}"
else
    echo -e "${YELLOW}修复 agent.py 导入语句...${NC}"
    sed -i 's/from src\.storage\.memory\.memory_saver import/from storage.memory.memory_saver import/' src/agents/agent.py
fi

# 检查 app.py sys.path 设置
if grep -q "sys.path.insert.*workspace_path" src/api/app.py; then
    echo -e "${GREEN}✓ app.py sys.path 设置正确${NC}"
else
    echo -e "${YELLOW}⚠️  请检查 app.py 中的 sys.path 设置${NC}"
fi

# 检查 Dockerfile
if grep -q "PYTHONPATH=/app:/app/src" Dockerfile; then
    echo -e "${GREEN}✓ Dockerfile 配置正确${NC}"
else
    echo -e "${YELLOW}修复 Dockerfile PYTHONPATH...${NC}"
    sed -i 's/COZE_WORKSPACE_PATH=\/app$/COZE_WORKSPACE_PATH=\/app \\\n    PYTHONPATH=\/app:\/app\/src/' Dockerfile
fi

echo ""
echo -e "${BLUE}步骤 3: 停止现有容器${NC}"
echo "-------------------------------------------"
docker-compose down

echo ""
echo -e "${BLUE}步骤 4: 重新构建镜像${NC}"
echo "-------------------------------------------"
docker-compose build --no-cache

echo ""
echo -e "${BLUE}步骤 5: 启动服务${NC}"
echo "-------------------------------------------"
docker-compose up -d

echo ""
echo -e "${BLUE}步骤 6: 等待服务启动（30秒）${NC}"
echo "-------------------------------------------"
sleep 30

echo ""
echo -e "${BLUE}步骤 7: 检查容器状态${NC}"
echo "-------------------------------------------"
docker-compose ps

echo ""
echo -e "${BLUE}步骤 8: 查看容器日志（最后 50 行）${NC}"
echo "-------------------------------------------"
docker-compose logs --tail=50

echo ""
echo -e "${BLUE}步骤 9: 测试健康检查${NC}"
echo "-------------------------------------------"
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
    echo -e "${GREEN}✓ 服务启动成功！${NC}"
    echo "健康检查响应: $HEALTH_RESPONSE"
    SUCCESS=true
else
    echo -e "${RED}✗ 服务启动失败${NC}"
    echo ""
    echo "请查看完整日志进行排查："
    echo "  docker-compose logs -f tnho-video-api"
    SUCCESS=false
fi

echo ""
echo "========================================="
if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}部署完成！服务运行正常${NC}"
else
    echo -e "${RED}部署完成，但服务启动失败${NC}"
fi
echo "========================================="
echo ""
echo "服务地址："
echo "  - API: http://47.110.72.148:8000"
echo "  - Health: http://47.110.72.148:8000/health"
echo "  - Nginx: http://47.110.72.148"
echo ""
echo "常用命令："
echo "  - 查看日志: docker-compose logs -f"
echo "  - 重启服务: docker-compose restart"
echo "  - 停止服务: docker-compose down"
echo "  - 测试 API: curl http://localhost:8000/health"
echo ""
