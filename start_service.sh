#!/bin/bash

# 停止旧进程
pkill -f "uvicorn.*main:app"
pkill -f "uvicorn.*app:app"

# 等待进程停止
sleep 2

# 进入项目目录
cd /workspace/projects

# 设置环境变量
export COZE_WORKSPACE_PATH=/workspace/projects

# 启动服务
nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 9000 --log-level info > /tmp/fastapi.log 2>&1 &

# 等待服务启动
sleep 3

# 检查服务状态
ps aux | grep uvicorn | grep -v grep

echo ""
echo "服务已启动，测试接口："
curl http://localhost:9000/health
echo ""
curl http://localhost:9000/api/test
echo ""
