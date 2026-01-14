#!/bin/bash
# 修复端口占用问题并重启服务
# 使用方法: bash fix_port_conflict.sh

set -e

echo "========================================="
echo "开始修复端口占用问题..."
echo "========================================="

# 1. 查找占用 8000 端口的进程
echo ""
echo "1. 查找占用 8000 端口的进程..."
PID=$(lsof -t -i:8000 2>/dev/null || echo "")

if [ ! -z "$PID" ]; then
    echo "发现以下进程占用端口 8000:"
    lsof -i:8000
    echo ""
    echo "正在停止这些进程..."
    for pid in $PID; do
        echo "  - 停止进程 $pid"
        kill -9 $pid
    done
    echo "已停止所有占用 8000 端口的进程"
else
    echo "端口 8000 未被占用"
fi

# 2. 等待端口释放
echo ""
echo "2. 等待端口释放..."
sleep 3

# 3. 验证端口是否释放
echo ""
echo "3. 验证端口状态..."
PID=$(lsof -t -i:8000 2>/dev/null || echo "")
if [ ! -z "$PID" ]; then
    echo "警告: 端口 8000 仍被占用，进程ID: $PID"
    echo "尝试强制停止..."
    kill -9 $PID 2>/dev/null || true
    sleep 2
fi

# 4. 停止 systemd 服务
echo ""
echo "4. 停止 tnho-api 服务..."
systemctl stop tnho-api || true

# 5. 等待服务完全停止
echo "等待服务完全停止..."
sleep 3

# 6. 重新启动服务
echo ""
echo "5. 启动 tnho-api 服务..."
systemctl start tnho-api

# 7. 等待服务启动
echo "等待服务启动..."
sleep 5

# 8. 检查服务状态
echo ""
echo "6. 检查服务状态..."
systemctl status tnho-api --no-pager || true

# 9. 查看最新日志
echo ""
echo "========================================="
echo "查看最新日志..."
echo "========================================="
journalctl -u tnho-api -n 30 --no-pager

# 10. 测试健康检查
echo ""
echo "========================================="
echo "测试 API 接口..."
echo "========================================="
sleep 2
curl -s http://localhost:8000/health || echo "健康检查失败"

echo ""
echo "========================================="
echo "修复完成！"
echo "========================================="
