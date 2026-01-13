#!/bin/bash

# 完整修复脚本 - 修复模块导入问题

set -e

echo "========================================="
echo "修复天虹紧固件视频生成 Agent"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "步骤 1: 检查并修复 Dockerfile"
echo "-------------------------------------------"

# 检查 Dockerfile 是否已包含 PYTHONPATH
if grep -q "PYTHONPATH=/app:/app/src" Dockerfile; then
    echo -e "${GREEN}✓ Dockerfile 已正确配置 PYTHONPATH${NC}"
else
    echo -e "${YELLOW}修复 Dockerfile 中的 PYTHONPATH...${NC}"
    sed -i 's/COZE_WORKSPACE_PATH=\/app$/COZE_WORKSPACE_PATH=\/app \\\n    PYTHONPATH=\/app:\/app\/src/' Dockerfile
    echo -e "${GREEN}✓ Dockerfile 已更新${NC}"
fi

echo ""
echo "步骤 2: 检查并修复 agent.py 导入语句"
echo "-------------------------------------------"

# 确保 agent.py 使用正确的导入语句（不带 src. 前缀）
if grep -q "from src.storage.memory.memory_saver import" src/agents/agent.py; then
    echo -e "${YELLOW}修复 agent.py 导入语句...${NC}"
    sed -i 's/from src\.storage\.memory\.memory_saver import/from storage.memory.memory_saver import/' src/agents/agent.py
    echo -e "${GREEN}✓ agent.py 已更新${NC}"
else
    echo -e "${GREEN}✓ agent.py 导入语句正确${NC}"
fi

echo ""
echo "步骤 3: 验证 app.py 中的 sys.path 设置"
echo "-------------------------------------------"

# 检查 app.py 中 sys.path 是否在导入之前
if grep -B 10 "from agents.agent import build_agent" src/api/app.py | grep -q "sys.path.insert"; then
    echo -e "${GREEN}✓ app.py 中 sys.path 设置正确${NC}"
else
    echo -e "${YELLOW}需要修复 app.py...${NC}"
    echo "请手动检查 src/api/app.py 文件"
    echo "确保 sys.path.insert(0, src_path) 在 from agents.agent import build_agent 之前"
fi

echo ""
echo "步骤 4: 显示关键文件内容验证"
echo "-------------------------------------------"

echo ""
echo "--- Dockerfile (环境变量部分) ---"
grep -A 4 "ENV PYTHONUNBUFFERED" Dockerfile || echo "未找到 ENV 配置"

echo ""
echo "--- src/agents/agent.py (导入部分) ---"
head -15 src/agents/agent.py | grep -A 1 "memory_saver"

echo ""
echo "--- src/api/app.py (sys.path 部分) ---"
head -20 src/api/app.py | grep -B 5 "from agents.agent import build_agent"

echo ""
echo "========================================="
echo -e "${GREEN}验证完成${NC}"
echo "========================================="
echo ""
echo "如果所有检查都通过，请执行以下命令重启服务："
echo ""
echo "  docker-compose down"
echo "  docker-compose build --no-cache"
echo "  docker-compose up -d"
echo ""
echo "然后等待 30 秒后查看日志："
echo "  docker-compose logs -f"
echo ""
