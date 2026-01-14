#!/bin/bash
# 从 GitHub 拉取最新代码并重启服务
# 在服务器上运行此脚本

echo "================================"
echo "从 GitHub 更新代码并重启服务"
echo "================================"
echo ""

# 1. 切换到项目目录
echo "[1/6] 切换到项目目录..."
cd /workspace/projects || exit 1
echo "✅ 当前目录: $(pwd)"
echo ""

# 2. 检查 Git 状态
echo "[2/6] 检查 Git 状态..."
git status --short
echo ""

# 3. 拉取最新代码
echo "[3/6] 从 GitHub 拉取最新代码..."
git fetch origin main
git reset --hard origin/main
echo "✅ 代码已更新"
echo ""

# 4. 清理 Python 缓存
echo "[4/6] 清理 Python 缓存..."
find src/ -name "*.pyc" -delete 2>/dev/null
find src/ -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
rm -rf .pytest_cache 2>/dev/null
echo "✅ 缓存已清理"
echo ""

# 5. 停止所有旧服务
echo "[5/6] 停止所有旧服务..."
pkill -9 -f "python3.*app" 2>/dev/null
pkill -9 -f "uvicorn" 2>/dev/null
pkill -9 -f "python.*app.main" 2>/dev/null
sleep 3
echo "✅ 旧服务已停止"
echo ""

# 6. 启动新的 FastAPI 服务
echo "[6/6] 启动新的 FastAPI 服务..."
nohup python3 app.py > /tmp/fastapi.log 2>&1 &
SERVICE_PID=$!
echo "✅ 服务已启动 (PID: $SERVICE_PID)"
echo ""
echo "等待服务启动..."
sleep 5

# 7. 验证服务状态
echo ""
echo "================================"
echo "验证服务状态"
echo "================================"

if ps -p $SERVICE_PID > /dev/null 2>&1; then
    echo "✅ 服务进程运行中 (PID: $SERVICE_PID)"
else
    echo "❌ 服务进程未运行"
    echo ""
    echo "查看日志："
    tail -100 /tmp/fastapi.log
    exit 1
fi

# 测试健康检查
echo ""
echo "测试健康检查..."
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ 健康检查通过"
else
    echo "⚠️  健康检查失败，但服务可能正在启动中..."
fi

# 测试企业微信接口
echo ""
echo "测试企业微信接口..."
curl -s http://localhost:8080/api/wechat/test
echo ""

echo ""
echo "================================"
echo "更新完成"
echo "================================"
echo ""
echo "查看日志: tail -f /tmp/fastapi.log"
echo "测试接口: curl -s http://localhost:8080/api/wechat/test"
echo ""
