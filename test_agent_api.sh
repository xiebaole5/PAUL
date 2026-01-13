#!/bin/bash

# 天虹紧固件视频生成 Agent API 测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_BASE_URL="http://47.110.72.148:8000"

echo "========================================="
echo "天虹紧固件视频生成 Agent API 测试"
echo "========================================="
echo ""

# 测试 1: 健康检查
echo -e "${BLUE}测试 1: 健康检查${NC}"
echo "GET /health"
echo "---"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ 健康检查通过${NC}"
    echo "响应: $BODY"
else
    echo -e "${RED}✗ 健康检查失败 (HTTP $HTTP_CODE)${NC}"
    echo "响应: $BODY"
fi
echo ""

# 测试 2: 测试 Agent 初始化
echo -e "${BLUE}测试 2: 测试 Agent 初始化${NC}"
echo "POST /agent/message"
echo "---"
AGENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/agent/message" \
    -H "Content-Type: application/json" \
    -d '{
        "message": "你好",
        "session_id": "test_session_001"
    }')
HTTP_CODE=$(echo "$AGENT_RESPONSE" | tail -n1)
BODY=$(echo "$AGENT_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✓ Agent 初始化成功${NC}"
    echo "响应: $BODY" | head -c 500
    echo ""
else
    echo -e "${YELLOW}Agent 响应 (HTTP $HTTP_CODE):${NC}"
    echo "$BODY" | head -c 500
    echo ""
fi
echo ""

# 测试 3: 测试脚本生成工具
echo -e "${BLUE}测试 3: 测试脚本生成工具${NC}"
echo "POST /agent/message"
echo "---"
SCRIPT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/agent/message" \
    -H "Content-Type: application/json" \
    -d '{
        "message": "请帮我生成一个关于品质保证的紧固件宣传视频脚本",
        "session_id": "test_session_002"
    }')
HTTP_CODE=$(echo "$SCRIPT_RESPONSE" | tail -n1)
BODY=$(echo "$SCRIPT_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✓ 脚本生成请求提交成功${NC}"
    echo "响应: $BODY" | head -c 500
    echo ""
else
    echo -e "${YELLOW}脚本生成响应 (HTTP $HTTP_CODE):${NC}"
    echo "$BODY" | head -c 500
    echo ""
fi
echo ""

# 测试 4: 测试视频生成接口（仅测试请求提交，不等待完成）
echo -e "${BLUE}测试 4: 测试视频生成接口${NC}"
echo "POST /api/generate-video"
echo "---"
VIDEO_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/api/generate-video" \
    -H "Content-Type: application/json" \
    -d '{
        "theme": "品质保证",
        "duration": 20,
        "prompt": "展示高品质紧固件，突出红色TNHO商标"
    }')
HTTP_CODE=$(echo "$VIDEO_RESPONSE" | tail -n1)
BODY=$(echo "$VIDEO_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✓ 视频生成请求提交成功${NC}"
    echo "响应: $BODY"
else
    echo -e "${YELLOW}视频生成响应 (HTTP $HTTP_CODE):${NC}"
    echo "$BODY"
fi
echo ""

echo "========================================="
echo -e "${GREEN}测试完成！${NC}"
echo "========================================="
echo ""
echo "如果所有测试通过，说明服务运行正常。"
echo "如果某些测试失败，请查看日志："
echo "  docker compose logs -f"
