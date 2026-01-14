#!/bin/bash
# 从 base64 编码恢复服务器代码

set -e

PROJECT_DIR="/root/tnho-video-api"
cd "$PROJECT_DIR"

echo "======================================"
echo "从 base64 恢复代码"
echo "======================================"

# Base64 编码的压缩包（这是关键文件）
BASE64_DATA="H4sIAAAAAAAAA+3..."

# 由于 base64 文件太大，我需要换个方法
echo "注意：由于文件较大，请使用以下方法之一："
echo ""
echo "方法 1: 从本地上传（推荐）"
echo "  1. 在本地执行: scp /tmp/tnho-api-fix.tar.gz root@47.110.72.148:/root/"
echo "  2. 在服务器执行:"
echo "     cd /root/tnho-video-api"
echo "     tar -xzf /root/tnho-api-fix.tar.gz"
echo "     docker-compose down && docker-compose up -d --build"
echo ""
echo "方法 2: 手动复制文件"
echo "  我会逐个提供文件内容供您复制"

echo ""
echo "请选择一种方法继续..."
