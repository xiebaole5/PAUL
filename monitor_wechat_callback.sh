#!/bin/bash

echo "=========================================="
echo "监控企业微信回调接口日志"
echo "=========================================="
echo ""
echo "正在监控日志文件: fastapi.log"
echo "按 Ctrl+C 停止监控"
echo ""
echo "=========================================="
echo ""

# 监控日志，只显示企业微信相关的日志
tail -f fastapi.log | grep --line-buffered "wechat_callback_simple"
