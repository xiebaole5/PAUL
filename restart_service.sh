#!/bin/bash

echo "=========================================="
echo "重启 FastAPI 服务"
echo "=========================================="

# 停止旧进程
echo "1. 停止旧进程..."
pkill -f "python app.py"
sleep 2

# 检查是否成功停止
if ps aux | grep -v grep | grep "python app.py" > /dev/null; then
    echo "   ⚠️  强制停止进程..."
    pkill -9 -f "python app.py"
    sleep 2
fi

echo "   ✅ 旧进程已停止"

# 启动新服务
echo ""
echo "2. 启动新服务..."
nohup python3 app.py > fastapi.log 2>&1 &
PID=$!

# 等待服务启动
sleep 3

# 检查服务状态
if ps -p $PID > /dev/null; then
    echo "   ✅ 服务已启动，PID: $PID"
else
    echo "   ❌ 服务启动失败"
    echo ""
    echo "查看日志:"
    tail -20 fastapi.log
    exit 1
fi

# 检查端口
echo ""
echo "3. 检查端口占用..."
if lsof -i :8080 > /dev/null; then
    echo "   ✅ 端口 8080 正常监听"
else
    echo "   ⚠️  端口 8080 未监听"
fi

echo ""
echo "=========================================="
echo "服务重启完成"
echo "=========================================="
echo ""
echo "服务信息:"
echo "  - 进程 ID: $PID"
echo "  - 监听端口: 8080"
echo "  - 日志文件: fastapi.log"
echo ""
echo "监控日志:"
echo "  tail -f fastapi.log"
echo ""
echo "监控企业微信日志:"
echo "  bash monitor_wechat_callback.sh"
echo ""
echo "=========================================="
