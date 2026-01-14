#!/bin/bash
# 天虹紧固件视频生成服务 - 停止脚本

echo "=========================================="
echo "天虹紧固件视频生成服务 - 停止"
echo "=========================================="

# 停止服务
echo "正在停止服务..."
systemctl stop tnho-api

# 等待服务停止
sleep 2

# 检查服务状态
if systemctl is-active --quiet tnho-api; then
    echo -e "\033[0;31m✗ 服务停止失败\033[0m"
    echo "服务仍在运行，请手动检查："
    echo "  systemctl status tnho-api"
    exit 1
else
    echo "=========================================="
    echo -e "\033[0;32m✓ 服务已停止\033[0m"
    echo "=========================================="
fi
