#!/bin/bash
# 简单的日志监控脚本

echo "=========================================="
echo "企业微信验证请求监控"
echo "=========================================="
echo ""
echo "监控文件: fastapi.log"
echo ""
echo "按 Ctrl+C 停止监控"
echo "=========================================="
echo ""

# 监控日志，显示企业微信相关的内容
tail -f fastapi.log | grep --line-buffered -E "企业微信|wechat|callback|收到请求"
