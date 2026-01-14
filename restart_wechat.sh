#!/bin/bash

echo "=== 重启 FastAPI 服务 ==="

# 停止旧进程
pkill -f "python app.py" || echo "没有运行中的进程"

# 等待进程完全停止
sleep 2

# 启动新服务
nohup venv/bin/python app.py > /tmp/fastapi.log 2>&1 &
PID=$!

echo "服务已启动，PID: $PID"
echo ""
echo "=== 服务已就绪，请在企业微信后台重新验证 ==="
echo "监控日志："
echo "  tail -f /tmp/fastapi.log"
echo ""
echo "验证参数："
echo "  回调 URL: http://47.110.72.148:8080/api/wechat/callback"
echo "  Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4"
