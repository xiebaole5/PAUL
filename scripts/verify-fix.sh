#!/bin/bash
# 验证修复效果的脚本
# 使用方法: bash scripts/verify-fix.sh

echo "=========================================="
echo "TNHO 视频生成服务 - 修复验证脚本"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected="$3"

    echo -n "测试 $name... "
    response=$(curl -s "$url" 2>&1)

    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}通过${NC}"
        return 0
    else
        echo -e "${RED}失败${NC}"
        echo "  期望包含: $expected"
        echo "  实际响应: $response"
        return 1
    fi
}

# 1. 检查应用进程
echo "1. 检查应用进程..."
if pgrep -f "uvicorn app:app" > /dev/null; then
    echo -e "${GREEN}✓ 应用正在运行${NC}"
else
    echo -e "${RED}✗ 应用未运行${NC}"
    exit 1
fi

# 2. 测试 API 健康检查
echo ""
echo "2. 测试 API 健康检查..."
test_endpoint "根路径" "http://localhost:8000/" "running"
test_endpoint "健康检查" "http://localhost:8000/health" "ok"

# 3. 测试图片上传接口（返回 HTTPS URL）
echo ""
echo "3. 测试图片上传接口（返回 HTTPS URL）..."
response=$(curl -s -X POST "http://localhost:8000/api/upload-image" \
  -F "file=@/etc/hostname")

if echo "$response" | grep -q "https://"; then
    echo -e "${GREEN}✓ 图片上传成功，返回 HTTPS URL${NC}"
    image_url=$(echo "$response" | grep -o '"image_url":"[^"]*"' | cut -d'"' -f4)
    echo "  URL: $image_url"
else
    echo -e "${RED}✗ 图片上传失败或返回 HTTP URL${NC}"
    echo "  响应: $response"
fi

# 4. 测试视频生成任务创建
echo ""
echo "4. 测试视频生成任务创建..."
response=$(curl -s -X POST "http://localhost:8000/api/generate-video" \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 5,
    "type": "video"
  }')

if echo "$response" | grep -q "task_id"; then
    echo -e "${GREEN}✓ 任务创建成功${NC}"
    task_id=$(echo "$response" | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)
    echo "  任务ID: $task_id"
else
    echo -e "${RED}✗ 任务创建失败${NC}"
    echo "  响应: $response"
    exit 1
fi

# 5. 测试进度查询
echo ""
echo "5. 测试进度查询..."
sleep 2  # 等待任务开始处理
response=$(curl -s "http://localhost:8000/api/progress/$task_id")

if echo "$response" | grep -q "task_id"; then
    echo -e "${GREEN}✓ 进度查询成功${NC}"
    status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    progress=$(echo "$response" | grep -o '"progress":[0-9]*' | cut -d':' -f2)
    echo "  状态: $status"
    echo "  进度: $progress%"
else
    echo -e "${RED}✗ 进度查询失败${NC}"
    echo "  响应: $response"
fi

# 6. 检查应用日志
echo ""
echo "6. 检查应用日志（最近20行）..."
if [ -f "logs/app.log" ]; then
    tail -20 logs/app.log
else
    echo -e "${YELLOW}⚠ 日志文件不存在${NC}"
fi

# 7. 数据库连接测试
echo ""
echo "7. 数据库连接测试..."
python3 << 'EOF'
import sys
sys.path.insert(0, '/root/tnho-video')
from storage.database.db import get_session

try:
    db = get_session()
    result = db.execute("SELECT 1")
    print(f"数据库连接成功: {result.fetchone()}")
    db.close()
except Exception as e:
    print(f"数据库连接失败: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 数据库连接正常${NC}"
else
    echo -e "${RED}✗ 数据库连接失败${NC}"
fi

echo ""
echo "=========================================="
echo "验证完成！"
echo "=========================================="
