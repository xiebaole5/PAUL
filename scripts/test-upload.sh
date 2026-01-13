#!/bin/bash

# 图片上传功能测试脚本
# 使用方法: bash scripts/test-upload.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "图片上传功能测试"
echo "=========================================="
echo ""

# API 地址
API_URL="http://47.110.72.148"

# 检查是否有测试图片
if [ ! -f "assets/image.png" ] && [ ! -f "assets/test.jpg" ]; then
    echo -e "${YELLOW}创建测试图片...${NC}"
    # 使用 base64 创建一个简单的 1x1 PNG 图片
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > assets/test.png
    TEST_IMAGE="assets/test.png"
else
    if [ -f "assets/image.png" ]; then
        TEST_IMAGE="assets/image.png"
    else
        TEST_IMAGE="assets/test.jpg"
    fi
fi

echo "使用测试图片: $TEST_IMAGE"
echo ""

# 测试 1: 上传图片
echo -e "${YELLOW}测试 1: 上传图片${NC}"
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/upload-image" \
  -F "file=@$TEST_IMAGE")

echo "响应内容:"
echo "$RESPONSE" | python3 -m json.tool
echo ""

# 检查是否成功
if echo "$RESPONSE" | grep -q '"success": true'; then
    echo -e "${GREEN}✓ 图片上传成功${NC}"

    # 提取图片 URL
    IMAGE_URL=$(echo "$RESPONSE" | grep -o '"image_url":"[^"]*"' | cut -d'"' -f4)
    echo "图片 URL: $IMAGE_URL"
    echo ""

    # 测试 2: 访问上传的图片
    echo -e "${YELLOW}测试 2: 访问上传的图片${NC}"
    echo ""

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$IMAGE_URL")

    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ 图片可以正常访问${NC} (HTTP $HTTP_CODE)"
    else
        echo -e "${RED}✗ 图片访问失败${NC} (HTTP $HTTP_CODE)"
    fi
    echo ""

else
    echo -e "${RED}✗ 图片上传失败${NC}"
    echo ""
    echo "错误信息:"
    echo "$RESPONSE"
    exit 1
fi

# 测试 3: 检查上传目录
echo -e "${YELLOW}测试 3: 检查上传目录${NC}"
echo ""

UPLOAD_DIR="/workspace/projects/assets/uploads"
if [ -d "$UPLOAD_DIR" ]; then
    FILE_COUNT=$(ls -1 "$UPLOAD_DIR" | wc -l)
    echo "上传目录: $UPLOAD_DIR"
    echo "已上传文件数: $FILE_COUNT"
    echo "文件列表:"
    ls -lh "$UPLOAD_DIR"
else
    echo -e "${RED}✗ 上传目录不存在${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "所有测试完成！"
echo "==========================================${NC}"
