#!/bin/bash

echo "=========================================="
echo "实时监控所有外部请求"
echo "=========================================="
echo ""
echo "监控标准:"
echo "  - 排除本地请求 (127.0.0.1)"
echo "  - 显示所有外部IP的请求"
echo ""
echo "按 Ctrl+C 停止监控"
echo ""
echo "=========================================="
echo ""

# 实时监控日志
tail -f fastapi.log | grep --line-buffered "收到请求" | while read line; do
    # 提取下一行的客户端IP
    ip=$(tail -n +$(grep -n "收到请求" fastapi.log | tail -1 | cut -d: -f1) fastapi.log | head -3 | grep "客户端 IP" | awk '{print $NF}')

    # 如果不是本地IP，显示完整的请求信息
    if [ "$ip" != "127.0.0.1" ]; then
        echo "🔔 检测到外部请求!"
        tail -n +$(grep -n "收到请求" fastapi.log | tail -1 | cut -d: -f1) fastapi.log | head -20
        echo "=========================================="
    fi
done
