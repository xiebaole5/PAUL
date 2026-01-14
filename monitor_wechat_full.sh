#!/bin/bash

echo "=========================================="
echo "企业微信URL验证 - 完整监控"
echo "=========================================="
echo ""
echo "监控内容:"
echo "  - 所有请求日志"
echo "  - 企业微信相关请求"
echo "  - 客户端IP（非本地）"
echo ""
echo "配置信息:"
echo "  - 回调URL: http://47.110.72.148:8080/api/wechat/callback"
echo "  - Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4"
echo "  - 日志文件: fastapi.log"
echo ""
echo "按 Ctrl+C 停止监控"
echo "=========================================="
echo ""

# 实时监控日志
tail -f fastapi.log | grep --line-buffered -E "收到请求|企业微信|wechat|callback" | while read line; do
    echo "$line"

    # 如果是企业微信请求，显示详细信息
    if echo "$line" | grep -q "企业微信 URL 验证请求"; then
        # 获取后续的详细日志
        echo ""
        tail -n +$(grep -n "企业微信 URL 验证请求" fastapi.log | tail -1 | cut -d: -f1) fastapi.log | head -15
        echo ""
        echo "=========================================="
    fi
done
