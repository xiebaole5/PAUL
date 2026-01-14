#!/bin/bash

echo "=== 实时监控企业微信验证请求 ==="
echo "等待企业微信发送验证请求..."
echo ""

PID=$(pgrep -f "python3 app.py" | head -1)

while true; do
    if [ -n "$PID" ]; then
        OUTPUT=$(tail -50 /proc/$PID/fd/1 2>/dev/null | grep -E "(callback|verify_url|echostr|Corp ID)")
        if [ -n "$OUTPUT" ]; then
            echo ""
            echo "=== 检测到企业微信验证请求 $(date) ==="
            tail -100 /proc/$PID/fd/1 2>/dev/null | grep -A 15 -B 5 "callback\|verify_url\|echostr\|Corp ID"
            echo ""
            break
        fi
    fi
    sleep 1
done

echo ""
echo "监控完成"
