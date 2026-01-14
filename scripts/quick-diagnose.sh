#!/bin/bash
# 快速诊断脚本 - 用于诊断小程序视频生成失败问题
# 使用方法: bash scripts/quick-diagnose.sh

echo "=========================================="
echo "TNHO 视频生成服务 - 快速诊断"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查服务器是否运行
echo "1. 检查服务器进程..."
if pgrep -f "uvicorn app:app" > /dev/null; then
    echo -e "${GREEN}✓ 应用正在运行${NC}"
    ps aux | grep "uvicorn app:app" | grep -v grep | head -2
else
    echo -e "${RED}✗ 应用未运行${NC}"
    echo "  启动命令: cd /root/tnho-video && nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &"
    exit 1
fi

# 2. 检查健康状态
echo ""
echo "2. 检查 API 健康状态..."
health_response=$(curl -s http://localhost:8000/health)
if echo "$health_response" | grep -q "ok"; then
    echo -e "${GREEN}✓ 健康检查通过${NC}"
    echo "  响应: $health_response"
else
    echo -e "${RED}✗ 健康检查失败${NC}"
    echo "  响应: $health_response"
    exit 1
fi

# 3. 测试创建任务
echo ""
echo "3. 测试创建视频生成任务..."
task_response=$(curl -s -X POST "http://localhost:8000/api/generate-video" \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 5,
    "type": "video"
  }')

if echo "$task_response" | grep -q "task_id"; then
    echo -e "${GREEN}✓ 任务创建成功${NC}"
    task_id=$(echo "$task_response" | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)
    echo "  任务ID: $task_id"
else
    echo -e "${RED}✗ 任务创建失败${NC}"
    echo "  响应: $task_response"
    echo ""
    echo "  可能原因:"
    echo "  1. Agent 构建失败"
    echo "  2. 数据库连接失败"
    echo "  3. 环境变量配置错误"
    echo ""
    echo "  建议操作:"
    echo "  1. 查看应用日志: tail -100 /root/tnho-video/logs/app.log"
    echo "  2. 检查环境变量: cat /root/tnho-video/.env"
    echo "  3. 测试数据库连接: bash /root/tnho-video/scripts/test-db.sh"
    exit 1
fi

# 4. 等待并检查任务进度
echo ""
echo "4. 等待任务开始执行..."
sleep 3

progress_response=$(curl -s "http://localhost:8000/api/progress/$task_id")
status=$(echo "$progress_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

echo -e "  当前状态: $status"

if [ "$status" = "failed" ]; then
    error_msg=$(echo "$progress_response" | grep -o '"error_message":"[^"]*"' | cut -d'"' -f4)
    echo -e "${RED}✗ 任务执行失败${NC}"
    echo "  错误信息: $error_msg"
    echo ""
    echo "  建议操作:"
    echo "  1. 查看详细日志: tail -100 /root/tnho-video/logs/app.log"
    echo "  2. 检查火山方舟 API Key: cat /root/tnho-video/.env | grep ARK_API_KEY"
    echo "  3. 测试数据库连接: bash /root/tnho-video/scripts/test-db.sh"
elif [ "$status" = "pending" ]; then
    echo -e "${YELLOW}⚠ 任务处于等待状态${NC}"
    echo "  这可能表示后台任务未正常启动"
    echo ""
    echo "  建议操作:"
    echo "  1. 检查应用日志: tail -100 /root/tnho-video/logs/app.log"
    echo "  2. 重启应用: pkill -f 'uvicorn app:app' && nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &"
fi

# 5. 检查最近的错误日志
echo ""
echo "5. 检查最近的错误日志..."
if [ -f "/root/tnho-video/logs/app.log" ]; then
    echo "  最近的错误日志（包含 ERROR 或 FAILED 或 failed）:"
    tail -100 /root/tnho-video/logs/app.log | grep -iE "error|failed|exception" | tail -10
else
    echo -e "${YELLOW}⚠ 日志文件不存在${NC}"
fi

# 6. 检查环境变量
echo ""
echo "6. 检查关键环境变量..."
if [ -f "/root/tnho-video/.env" ]; then
    echo "  .env 文件存在"
    
    # 检查 API Key
    if grep -q "ARK_API_KEY=" /root/tnho-video/.env; then
        echo -e "  ${GREEN}✓ ARK_API_KEY 已配置${NC}"
    else
        echo -e "  ${RED}✗ ARK_API_KEY 未配置${NC}"
    fi
    
    # 检查数据库 URL
    if grep -q "PGDATABASE_URL=" /root/tnho-video/.env; then
        echo -e "  ${GREEN}✓ PGDATABASE_URL 已配置${NC}"
    else
        echo -e "  ${RED}✗ PGDATABASE_URL 未配置${NC}"
    fi
    
    # 检查外部 URL
    if grep -q "EXTERNAL_BASE_URL=" /root/tnho-video/.env; then
        external_url=$(grep "EXTERNAL_BASE_URL=" /root/tnho-video/.env | cut -d'=' -f2)
        if echo "$external_url" | grep -q "https://"; then
            echo -e "  ${GREEN}✓ EXTERNAL_BASE_URL 使用 HTTPS: $external_url${NC}"
        else
            echo -e "  ${YELLOW}⚠ EXTERNAL_BASE_URL 未使用 HTTPS: $external_url${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ EXTERNAL_BASE_URL 未配置${NC}"
    fi
else
    echo -e "${RED}✗ .env 文件不存在${NC}"
fi

# 7. 小程序配置检查
echo ""
echo "7. 小程序配置检查..."
echo "  请确认以下配置："
echo "  1. 小程序 API 地址: https://tnho-fasteners.com（必须 HTTPS）"
echo "  2. 小程序后台域名白名单已配置:"
echo "     - request: https://tnho-fasteners.com"
echo "     - uploadFile: https://tnho-fasteners.com"
echo "     - downloadFile: https://tnho-fasteners.com"
echo "  3. 小程序请求超时时间: 30秒（视频生成 5秒即可，因为是异步）"

# 8. 总结
echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果任务创建失败，请："
echo "  1. 查看完整日志: tail -100 /root/tnho-video/logs/app.log"
echo "  2. 运行完整验证: bash /root/tnho-video/scripts/full-verify.sh"
echo "  3. 查看详细排查指南: cat /root/tnho-video/docs/小程序视频生成失败排查指南.md"
echo ""
echo "如果任务创建成功但执行失败，请："
echo "  1. 使用 task_id 查询进度: curl http://localhost:8000/api/progress/$task_id"
echo "  2. 查看错误信息（error_message 字段）"
echo "  3. 检查火山方舟 API Key 是否有效"
