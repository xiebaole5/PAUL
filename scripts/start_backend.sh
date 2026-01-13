#!/bin/bash

# 天虹紧固件视频生成后端启动脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="/workspace/projects"
cd "$PROJECT_ROOT"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  天虹紧固件视频生成后端服务${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查 Python 版本
echo -e "${YELLOW}[1/5] 检查 Python 版本...${NC}"
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "当前 Python 版本: $python_version"
echo ""

# 检查依赖
echo -e "${YELLOW}[2/5] 检查依赖...${NC}"
if [ -f "requirements.txt" ]; then
    echo "检查依赖是否已安装..."
    pip list | grep -q "fastapi" || {
        echo -e "${RED}依赖未安装，正在安装...${NC}"
        pip install -r requirements.txt
    }
    echo -e "${GREEN}✓ 依赖检查完成${NC}"
else
    echo -e "${RED}错误：未找到 requirements.txt${NC}"
    exit 1
fi
echo ""

# 检查 API Key
echo -e "${YELLOW}[3/5] 检查 API Key 配置...${NC}"
if [ -z "$ARK_API_KEY" ]; then
    echo -e "${RED}警告：未设置 ARK_API_KEY 环境变量${NC}"
    echo "请设置 API Key："
    echo "  export ARK_API_KEY=your_api_key_here"
    echo ""
    echo "或在 .env 文件中配置："
    echo "  ARK_API_KEY=your_api_key_here"
    echo ""
    read -p "是否继续启动？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ API Key 已配置${NC}"
fi
echo ""

# 检查配置文件
echo -e "${YELLOW}[4/5] 检查配置文件...${NC}"
if [ -f "config/agent_llm_config.json" ]; then
    echo -e "${GREEN}✓ Agent 配置文件存在${NC}"
else
    echo -e "${RED}错误：未找到 config/agent_llm_config.json${NC}"
    exit 1
fi

if [ -f "src/api/app.py" ]; then
    echo -e "${GREEN}✓ API 服务文件存在${NC}"
else
    echo -e "${RED}错误：未找到 src/api/app.py${NC}"
    exit 1
fi
echo ""

# 启动服务
echo -e "${YELLOW}[5/5] 启动服务...${NC}"
echo "服务地址: http://localhost:8000"
echo "健康检查: http://localhost:8000/health"
echo "API 文档: http://localhost:8000/docs"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}服务启动中...${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查端口是否被占用
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}警告：端口 8000 已被占用${NC}"
    read -p "是否尝试停止占用进程？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        lsof -ti:8000 | xargs kill -9
        sleep 1
    else
        echo "启动取消"
        exit 1
    fi
fi

# 启动服务
cd "$PROJECT_ROOT"
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload
