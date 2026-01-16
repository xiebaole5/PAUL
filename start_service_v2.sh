#!/bin/bash

# 天虹紧固件 FastAPI 服务启动脚本
# 简化版 - 自动检测项目路径

echo "=== 天虹紧固件 FastAPI 服务启动 ==="
echo ""

# 1. 停止旧进程
echo "[1/4] 停止旧进程..."
pkill -f "uvicorn.*main:app" 2>/dev/null
pkill -f "uvicorn.*app:app" 2>/dev/null
sleep 2

# 2. 检测项目路径
if [ -d "$(pwd)/src" ]; then
    PROJECT_DIR=$(pwd)
elif [ -d "/workspace/projects/src" ]; then
    PROJECT_DIR="/workspace/projects"
else
    echo "❌ 错误：找不到项目目录"
    echo "当前目录: $(pwd)"
    exit 1
fi

echo "[2/4] 项目目录: $PROJECT_DIR"
cd $PROJECT_DIR

# 3. 设置环境变量
echo "[3/4] 设置环境变量..."
export COZE_WORKSPACE_PATH=$PROJECT_DIR
export PYTHONPATH=$PROJECT_DIR/src:$PYTHONPATH

# 4. 启动服务
echo "[4/4] 启动 FastAPI 服务（8080端口）..."
nohup python3 -m uvicorn src.main:app \
  --host 0.0.0.0 \
  --port 8080 \
  --log-level info \
  > /tmp/fastapi.log 2>&1 &

sleep 5

# 5. 检查服务状态
echo ""
echo "=== 服务状态检查 ==="
if ps aux | grep -v grep | grep -q "uvicorn.*src.main:app"; then
    echo "✅ FastAPI 服务已启动"
    echo "   端口: 8080"
    echo "   日志: /tmp/fastapi.log"
    echo ""
    echo "测试接口："
    curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/health
else
    echo "❌ 服务启动失败"
    echo ""
    echo "错误日志："
    tail -30 /tmp/fastapi.log
    exit 1
fi
