#!/bin/bash

echo "=========================================="
echo "测试并查看完整日志"
echo "=========================================="

# 清空日志
echo "" > fastapi.log

# 重启服务
pkill -f "python app.py" || true
sleep 2

# 启动服务
nohup python3 app.py > fastapi.log 2>&1 &
sleep 3

# 发送测试请求
echo "发送测试请求..."
curl -s http://localhost:8080/api/wechat/test > /dev/null

echo ""
echo "查看日志（最后50行）："
echo "=========================================="
tail -50 fastapi.log
echo "=========================================="
