#!/bin/bash

echo "=== 天虹视频生成服务 - 功能测试脚本 ==="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 基础 URL
BASE_URL="http://localhost:8000"
BASE_URL_EXTERNAL="http://47.110.72.148"

# 函数：打印结果
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# 1. 测试健康检查
echo "1. 测试健康检查接口..."
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/health)
if [ "$HEALTH_STATUS" = "200" ]; then
    print_result 0 "健康检查通过 (HTTP 200)"
    curl -s ${BASE_URL}/health | jq .
else
    print_result 1 "健康检查失败 (HTTP $HEALTH_STATUS)"
fi
echo ""

# 2. 测试根路径
echo "2. 测试根路径接口..."
ROOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/)
if [ "$ROOT_STATUS" = "200" ]; then
    print_result 0 "根路径访问正常 (HTTP 200)"
    curl -s ${BASE_URL}/ | jq .
else
    print_result 1 "根路径访问失败 (HTTP $ROOT_STATUS)"
fi
echo ""

# 3. 测试 API 文档
echo "3. 测试 API 文档访问..."
DOCS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/docs)
if [ "$DOCS_STATUS" = "200" ]; then
    print_result 0 "API 文档可访问 (HTTP 200)"
    echo "   内部访问: ${BASE_URL}/docs"
    echo "   外部访问: ${BASE_URL_EXTERNAL}/docs"
else
    print_result 1 "API 文档访问失败 (HTTP $DOCS_STATUS)"
fi
echo ""

# 4. 测试脚本生成接口
echo "4. 测试视频脚本生成接口..."
SCRIPT_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "script"
  }')

if echo "$SCRIPT_RESPONSE" | grep -q '"success":true'; then
    print_result 0 "脚本生成成功"
    echo "$SCRIPT_RESPONSE" | jq .
else
    print_result 1 "脚本生成失败"
    echo "$SCRIPT_RESPONSE" | jq .
fi
echo ""

# 5. 检查容器资源使用
echo "5. 检查容器资源使用..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" tnho-video-api
echo ""

# 6. 检查容器内 Python 进程
echo "6. 检查容器内进程..."
docker-compose exec -T tnho-video-api ps aux | grep -E "(uvicorn|python)" | head -5
echo ""

echo "=== 测试完成 ==="
echo ""
echo "如需测试更多功能，请访问 API 文档："
echo "  内部: ${BASE_URL}/docs"
echo "  外部: ${BASE_URL_EXTERNAL}/docs"
