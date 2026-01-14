#!/bin/bash

echo "=== 监控企业微信验证请求 ==="
echo "等待企业微信发送验证请求..."
echo ""

while true; do
    if tail -20 /proc/$(pgrep -f "python3 app.py" | head -1)/fd/1 | grep -q "callback"; then
        echo ""
        echo "=== 检测到企业微信验证请求 ==="
        tail -50 /proc/$(pgrep -f "python3 app.py" | head -1)/fd/1 | grep -A 10 -B 5 "callback\|verify_url\|echostr\|Corp ID"
        echo ""
        break
    fi
    sleep 1
done

echo "监控完成"
