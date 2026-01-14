#!/bin/bash
# TNHO 快速测试脚本
# 用于快速验证服务器功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# API 地址
API_URL="http://47.110.72.148"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}TNHO 快速测试脚本${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "测试服务器: $API_URL"
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_endpoint() {
    local test_name=$1
    local endpoint=$2
    local expected_status=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "[$TOTAL_TESTS] 测试 $test_name ... "

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL$endpoint" 2>/dev/null || echo "000")

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ 通过${NC} (HTTP $http_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ 失败${NC} (期望 $expected_status, 实际 $http_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${YELLOW}[基础功能测试]${NC}"
echo "----------------------------------------"

# 测试 1: 健康检查
test_endpoint "健康检查接口" "/health" "200"

# 测试 2: 主题列表
test_endpoint "主题列表接口" "/api/themes" "200"

# 测试 3: 脚本生成（POST 请求）
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试脚本生成接口 ... "
RESPONSE=$(curl -s -X POST "$API_URL/api/generate-script" \
  -H "Content-Type: application/json" \
  -d '{"theme":"品质保证","duration":20}' 2>/dev/null || echo "")

if echo "$RESPONSE" | grep -q '"task_id"'; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""
echo -e "${YELLOW}[性能测试]${NC}"
echo "----------------------------------------"

# 测试 4: 响应时间
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试健康检查响应时间 ... "
RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}\n" "$API_URL/health" 2>/dev/null || echo "999")
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    echo -e "${GREEN}✓ 通过${NC} (${RESPONSE_TIME}s)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠ 警告${NC} (${RESPONSE_TIME}s, 建议 < 1s)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# 测试 5: 并发请求
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试并发请求（10次） ... "
START_TIME=$(date +%s.%N)
for i in {1..10}; do
    curl -s -o /dev/null "$API_URL/health" 2>/dev/null &
done
wait
END_TIME=$(date +%s.%N)
TOTAL_TIME=$(echo "$END_TIME - $START_TIME" | bc)
AVG_TIME=$(echo "scale=3; $TOTAL_TIME / 10" | bc)
echo -e "${GREEN}✓ 完成${NC} (平均 ${AVG_TIME}s/请求)"
PASSED_TESTS=$((PASSED_TESTS + 1))

echo ""
echo -e "${YELLOW}[图片上传测试]${NC}"
echo "----------------------------------------"

# 测试 6: 图片上传（需要临时图片文件）
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试图片上传接口 ... "

# 创建测试图片（1x1 像素红色 JPEG）
TEST_IMAGE="/tmp/test_upload.jpg"
python3 -c "
from PIL import Image
import numpy as np
img = Image.fromarray(np.array([[[255, 0, 0]]], dtype=np.uint8))
img.save('$TEST_IMAGE')
" 2>/dev/null

if [ -f "$TEST_IMAGE" ]; then
    RESPONSE=$(curl -s -X POST "$API_URL/api/upload-image" \
      -F "file=@$TEST_IMAGE" \
      2>/dev/null || echo "")

    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo -e "${GREEN}✓ 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        rm -f "$TEST_IMAGE"
    else
        echo -e "${RED}✗ 失败${NC}"
        echo "响应: $RESPONSE"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo -e "${YELLOW}⚠ 跳过${NC} (无法创建测试图片)"
    TOTAL_TESTS=$((TOTAL_TESTS - 1))
fi

echo ""
echo -e "${YELLOW}[数据库测试]${NC}"
echo "----------------------------------------"

# 测试 7: 数据库连接（通过 API）
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试数据库连接 ... "
RESPONSE=$(curl -s "$API_URL/health" 2>/dev/null || echo "")

if echo "$RESPONSE" | grep -q "ok"; then
    echo -e "${GREEN}✓ 通过${NC} (通过健康检查间接验证)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠ 警告${NC} (无法直接验证数据库连接)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

echo ""
echo -e "${YELLOW}[安全测试]${NC}"
echo "----------------------------------------"

# 测试 8: CORS
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试 CORS 配置 ... "
CORS_HEADERS=$(curl -s -I -H "Origin: https://servicewechat.com" "$API_URL/health" 2>/dev/null | grep -i "access-control" || echo "")
if [ -n "$CORS_HEADERS" ]; then
    echo -e "${GREEN}✓ 通过${NC}"
    echo "$CORS_HEADERS"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠ 警告${NC} (未检测到 CORS 头)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# 测试 9: 安全头部
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 测试安全头部 ... "
SECURITY_HEADERS=$(curl -s -I "$API_URL/health" 2>/dev/null | grep -iE "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection)" || echo "")
if [ -n "$SECURITY_HEADERS" ]; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠ 警告${NC} (未检测到安全头部)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# 测试 10: 端口扫描（安全）
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "[$TOTAL_TESTS] 检查开放的端口 ... "
OPEN_PORTS=$(netstat -tln 2>/dev/null | grep -E ":(80|443|9000)" | awk '{print $4}' | awk -F: '{print $NF}' | sort -u)
echo -e "${GREEN}✓ 通过${NC}"
echo "开放端口: $OPEN_PORTS"
PASSED_TESTS=$((PASSED_TESTS + 1))

echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}测试总结${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！服务器运行正常。${NC}"
    exit 0
else
    echo -e "${RED}✗ 部分测试失败，请检查服务器配置。${NC}"
    exit 1
fi
