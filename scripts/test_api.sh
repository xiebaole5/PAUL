#!/bin/bash
# 快速测试 API 服务

echo "======================================"
echo "天虹紧固件 API 测试工具"
echo "======================================"
echo ""

# 测试地址列表
TEST_URLS=(
    "http://localhost:8000"
    "http://127.0.0.1:8000"
    "http://47.110.72.148:8000"
    "http://tnho-fasteners.com"
)

echo "1. 测试服务健康状态..."
echo "--------------------------------------"
for url in "${TEST_URLS[@]}"; do
    echo -n "测试 $url/health ... "
    result=$(curl -s --connect-timeout 3 "$url/health" 2>/dev/null | head -c 100)
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        echo "✅ 成功"
        echo "   响应: $result"
        BASE_URL="$url"
        break
    else
        echo "❌ 失败"
    fi
done
echo ""

if [ -z "$BASE_URL" ]; then
    echo "❌ 所有测试地址均无法访问"
    echo ""
    echo "请检查："
    echo "  1. 服务是否启动: ps aux | grep uvicorn"
    echo "  2. 端口是否监听: netstat -tlnp | grep 8000"
    echo "  3. 防火墙是否开放"
    exit 1
fi

echo "2. 测试创建视频生成任务..."
echo "--------------------------------------"
response=$(curl -s -X POST "$BASE_URL/api/generate-video" \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "测试产品",
    "theme": "品质保证",
    "duration": 10,
    "type": "video"
  }' 2>/dev/null)

if [ $? -eq 0 ]; then
    task_id=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('task_id', ''))" 2>/dev/null)
    if [ -n "$task_id" ]; then
        echo "✅ 任务创建成功"
        echo "   任务ID: $task_id"
        echo ""
        echo "3. 查询任务进度..."
        echo "--------------------------------------"
        sleep 2
        progress_response=$(curl -s "$BASE_URL/api/progress/$task_id" 2>/dev/null)
        if [ $? -eq 0 ]; then
            status=$(echo "$progress_response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null)
            progress=$(echo "$progress_response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('progress', 0))" 2>/dev/null)
            message=$(echo "$progress_response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', ''))" 2>/dev/null)
            echo "✅ 进度查询成功"
            echo "   状态: $status"
            echo "   进度: $progress%"
            echo "   消息: $message"
        else
            echo "❌ 进度查询失败"
        fi
    else
        echo "❌ 无法解析任务ID"
        echo "   响应: $response"
    fi
else
    echo "❌ 任务创建失败"
fi

echo ""
echo "======================================"
echo "测试完成！"
echo "======================================"
