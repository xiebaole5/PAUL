#!/bin/bash
# 完整的服务器验证测试脚本
# 使用方法: bash scripts/full-verify.sh

echo "=========================================="
echo "TNHO 视频生成服务 - 完整验证测试"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# 测试函数
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected="$3"

    echo -n "测试 $name... "
    response=$(curl -s "$url" 2>&1)

    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}通过${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}失败${NC}"
        echo "  期望包含: $expected"
        echo "  实际响应: $response"
        ((FAIL_COUNT++))
        return 1
    fi
}

# 1. 检查应用进程
echo "1. 检查应用进程..."
if pgrep -f "uvicorn app:app" > /dev/null; then
    echo -e "${GREEN}✓ 应用正在运行${NC}"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ 应用未运行${NC}"
    ((FAIL_COUNT++))
fi

# 2. 测试 API 健康检查
echo ""
echo "2. 测试 API 健康检查..."
test_endpoint "根路径" "http://localhost:8000/" "running"
test_endpoint "健康检查" "http://localhost:8000/health" "ok"

# 3. 创建测试图片文件
echo ""
echo "3. 创建测试图片文件..."
TEST_IMAGE="/tmp/test_image.png"
python3 -c "
from PIL import Image
import os

# 创建一个 100x100 的红色 PNG 图片
img = Image.new('RGB', (100, 100), color='red')
img.save('$TEST_IMAGE')
print(f'测试图片已创建: {os.path.exists(\"$TEST_IMAGE\")}')
" 2>/dev/null

if [ -f "$TEST_IMAGE" ]; then
    echo -e "${GREEN}✓ 测试图片创建成功${NC}"
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠ 使用备选测试文件${NC}"
    # 使用系统自带的图片文件
    if [ -f "/usr/share/pixmaps/faces/smile.png" ]; then
        TEST_IMAGE="/usr/share/pixmaps/faces/smile.png"
        echo "使用系统图片: $TEST_IMAGE"
    else
        echo -e "${RED}✗ 无法创建测试图片，跳过图片上传测试${NC}"
        TEST_IMAGE=""
    fi
fi

# 4. 测试图片上传接口
if [ -n "$TEST_IMAGE" ] && [ -f "$TEST_IMAGE" ]; then
    echo ""
    echo "4. 测试图片上传接口（返回 HTTPS URL）..."
    response=$(curl -s -X POST "http://localhost:8000/api/upload-image" \
      -F "file=@$TEST_IMAGE")

    if echo "$response" | grep -q "success.*true" && echo "$response" | grep -q "https://"; then
        echo -e "${GREEN}✓ 图片上传成功，返回 HTTPS URL${NC}"
        image_url=$(echo "$response" | grep -o '"image_url":"[^"]*"' | cut -d'"' -f4)
        echo "  URL: $image_url"
        ((PASS_COUNT++))
    else
        echo -e "${RED}✗ 图片上传失败或未返回 HTTPS URL${NC}"
        echo "  响应: $response"
        ((FAIL_COUNT++))
    fi
fi

# 5. 测试视频生成任务创建
echo ""
echo "5. 测试视频生成任务创建..."
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
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ 任务创建失败${NC}"
    echo "  响应: $response"
    ((FAIL_COUNT++))
    task_id=""
fi

# 6. 测试进度查询（等待任务开始）
if [ -n "$task_id" ]; then
    echo ""
    echo "6. 测试进度查询..."
    sleep 3  # 等待任务开始处理
    response=$(curl -s "http://localhost:8000/api/progress/$task_id")

    if echo "$response" | grep -q "task_id"; then
        echo -e "${GREEN}✓ 进度查询成功${NC}"
        status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        progress=$(echo "$response" | grep -o '"progress":[0-9]*' | cut -d':' -f2)
        echo "  状态: $status"
        echo "  进度: $progress%"
        ((PASS_COUNT++))
    else
        echo -e "${RED}✗ 进度查询失败${NC}"
        echo "  响应: $response"
        ((FAIL_COUNT++))
    fi
fi

# 7. 等待任务完成并检查结果
if [ -n "$task_id" ]; then
    echo ""
    echo "7. 等待任务完成..."
    echo "  等待 20 秒..."
    sleep 20

    response=$(curl -s "http://localhost:8000/api/progress/$task_id")
    status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    if [ "$status" = "completed" ]; then
        echo -e "${GREEN}✓ 任务已完成${NC}"
        ((PASS_COUNT++))

        # 检查视频 URL
        if echo "$response" | grep -q '"video_urls"' && echo "$response" | grep -q "https://"; then
            echo -e "${GREEN}✓ 视频生成成功，返回 HTTPS URL${NC}"
            video_url=$(echo "$response" | grep -o '"video_urls":\[[^]]*\]' | head -1)
            echo "  视频URL: $(echo "$video_url" | head -c 100)..."
            ((PASS_COUNT++))
        else
            echo -e "${YELLOW}⚠ 视频URL格式异常${NC}"
        fi
    elif [ "$status" = "failed" ]; then
        echo -e "${RED}✗ 任务失败${NC}"
        error=$(echo "$response" | grep -o '"error_message":"[^"]*"' | cut -d'"' -f4)
        echo "  错误信息: $error"
        ((FAIL_COUNT++))
    else
        echo -e "${YELLOW}⚠ 任务仍在进行中: $status${NC}"
    fi
fi

# 8. 数据库连接测试
echo ""
echo "8. 数据库连接测试..."
python3 << 'EOF'
import sys
import os
from pathlib import Path

# 添加 src 到路径
current_dir = Path.cwd()
src_path = current_dir / "src"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

# 手动读取 .env 文件
env_file = current_dir / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

try:
    from storage.database.db import get_session
    from sqlalchemy import text
    
    db = get_session()
    result = db.execute(text("SELECT 1"))
    print(f"✓ 数据库连接成功")
    
    # 检查表是否存在
    result = db.execute(text("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = 'video_generation_tasks'
        )
    """))
    exists = result.fetchone()[0]
    print(f"✓ video_generation_tasks表存在: {exists}")
    
    # 统计任务数量
    result = db.execute(text("""
        SELECT
            status,
            COUNT(*) as count
        FROM video_generation_tasks
        GROUP BY status
    """))
    print(f"✓ 任务统计:")
    for row in result:
        print(f"  - {row[0]}: {row[1]}")
    
    db.close()
    sys.exit(0)
except Exception as e:
    print(f"✗ 数据库连接失败: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    ((PASS_COUNT+=3))
else
    ((FAIL_COUNT+=3))
fi

# 9. 检查应用日志（最近30行）
echo ""
echo "9. 检查应用日志（最近30行）..."
if [ -f "logs/app.log" ]; then
    echo "=========================================="
    tail -30 logs/app.log
    echo "=========================================="
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠ 日志文件不存在${NC}"
fi

# 汇总
echo ""
echo "=========================================="
echo "测试汇总"
echo "=========================================="
echo -e "通过: ${GREEN}${PASS_COUNT}${NC} 项"
echo -e "失败: ${RED}${FAIL_COUNT}${NC} 项"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}✗ 有 ${FAIL_COUNT} 项测试失败${NC}"
    exit 1
fi
