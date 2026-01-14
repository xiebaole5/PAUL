#!/bin/bash
# 服务器快速更新脚本 - 直接复制粘贴执行

set -e  # 遇到错误立即退出

echo "================================"
echo "开始更新服务器代码"
echo "================================"
echo ""

# 1. 切换到项目目录
echo "[1/8] 切换到项目目录..."
cd /workspace/projects
pwd

# 2. 拉取最新代码
echo ""
echo "[2/8] 拉取最新代码..."
git fetch origin main
git reset --hard origin/main

# 3. 清理 Python 缓存
echo ""
echo "[3/8] 清理 Python 缓存..."
find src/ -name "*.pyc" -delete 2>/dev/null
find src/ -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
echo "✅ 缓存已清理"

# 4. 停止所有旧服务
echo ""
echo "[4/8] 停止所有旧服务..."
pkill -9 -f "python3.*app" 2>/dev/null || true
pkill -9 -f "uvicorn" 2>/dev/null || true
pkill -9 -f "python.*app.main" 2>/dev/null || true
sleep 3
echo "✅ 旧服务已停止"

# 5. 验证服务已停止
echo ""
echo "[5/8] 验证服务状态..."
RUNNING_PROCS=$(ps aux | grep python | grep -E "(uvicorn|app)" | grep -v grep | wc -l)
if [ "$RUNNING_PROCS" -eq 0 ]; then
    echo "✅ 所有服务已停止"
else
    echo "⚠️  仍有 $RUNNING_PROCS 个 Python 进程在运行"
    ps aux | grep python | grep -E "(uvicorn|app)" | grep -v grep
fi

# 6. 启动新的 FastAPI 服务
echo ""
echo "[6/8] 启动新的 FastAPI 服务..."
nohup python3 app.py > /tmp/fastapi.log 2>&1 &
SERVICE_PID=$!
echo "✅ 服务已启动 (PID: $SERVICE_PID)"

# 7. 等待服务启动
echo ""
echo "[7/8] 等待服务启动..."
sleep 5

# 8. 验证服务状态
echo ""
echo "[8/8] 验证服务状态..."
echo ""
echo "检查进程状态:"
if ps -p $SERVICE_PID > /dev/null 2>&1; then
    echo "✅ 服务进程运行中 (PID: $SERVICE_PID)"
else
    echo "❌ 服务进程未运行"
    echo ""
    echo "查看启动日志:"
    tail -100 /tmp/fastapi.log
    exit 1
fi

echo ""
echo "健康检查:"
HEALTH_RESULT=$(curl -s http://localhost:8080/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ $HEALTH_RESULT"
else
    echo "⚠️  健康检查失败，服务可能还在启动中..."
fi

echo ""
echo "企业微信接口测试:"
WECHAT_RESULT=$(curl -s http://localhost:8080/api/wechat/test 2>/dev/null)
echo "$WECHAT_RESULT"

if echo "$WECHAT_RESULT" | grep -q '"status":"ok"'; then
    echo "✅ 企业微信接口正常"
else
    echo "❌ 企业微信接口异常"
fi

echo ""
echo "================================"
echo "更新完成！"
echo "================================"
echo ""
echo "查看日志: tail -f /tmp/fastapi.log"
echo "测试接口: curl -s http://localhost:8080/api/wechat/test"
echo ""
echo "如果需要测试企业微信 URL 验证，请运行:"
echo "python3 scripts/quick_wechat_test.py"
echo ""
