#!/bin/bash
# 实时监控企业微信验证日志

echo "监控 FastAPI 日志输出 (PID 1188)..."
echo "按 Ctrl+C 停止监控"
echo ""

tail -f /proc/1188/fd/1 | grep -E "(企业微信|echostr|Corp ID|verify_url|decrypt)" --line-buffered
