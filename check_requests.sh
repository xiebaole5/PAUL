#!/bin/bash

echo "=== 检查网络请求 ==="
echo ""
echo "最近的请求（前20条）："
tail -20 /proc/$(pgrep -f "python3 app.py" | head -1)/fd/1 | grep -E "(GET|POST|callback)"
echo ""

echo "当前进程状态："
ps aux | grep "python3 app.py" | grep -v grep
echo ""

echo "监听端口："
netstat -tlnp | grep 8080
echo ""
