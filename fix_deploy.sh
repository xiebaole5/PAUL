#!/bin/bash
# 修复部署脚本 - 使用 --break-system-packages 选项
# 在服务器47.110.72.148上执行（在 /workspace/projects 目录下）

set -e

echo "=== 修复部署 - 安装依赖并启动服务 ==="
echo ""

# 检查目录
if [ ! -f "requirements.txt" ]; then
    echo "❌ 错误：请在 /workspace/projects 目录下执行此脚本"
    exit 1
fi

# 第一步：停止旧服务
echo "[1/3] 停止旧服务..."
pkill -9 -f uvicorn 2>/dev/null || true
sleep 2
echo "✅ 已停止"
echo ""

# 第二步：安装依赖（使用 --break-system-packages）
echo "[2/3] 安装依赖..."
echo "这可能需要5-10分钟，请耐心等待..."
echo ""

# 升级pip
pip3 install --upgrade pip --break-system-packages

# 安装依赖
pip3 install -r requirements.txt --break-system-packages

echo ""
echo "✅ 依赖安装完成"
echo ""

# 第三步：启动服务
echo "[3/3] 启动服务..."
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH

nohup python3 -m uvicorn src.main:app \
  --host 0.0.0.0 \
  --port 8080 \
  --log-level info \
  > /tmp/fastapi.log 2>&1 &

sleep 5

if ps aux | grep -v grep | grep -q "uvicorn.*src.main:app"; then
    echo "✅ 服务已启动"
    echo ""
    echo "测试接口："
    curl -s http://localhost:8080/health
else
    echo "❌ 服务启动失败"
    echo ""
    echo "错误日志："
    tail -50 /tmp/fastapi.log
    exit 1
fi

echo ""
echo "=== 部署完成 ==="
