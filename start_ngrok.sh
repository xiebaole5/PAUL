#!/bin/bash

echo "=========================================="
echo "启动ngrok隧道"
echo "=========================================="
echo ""

# 检查ngrok是否安装
if ! command -v ngrok &> /dev/null; then
    echo "❌ 错误: ngrok未安装"
    echo ""
    echo "请先安装ngrok:"
    echo "  macOS: brew install ngrok"
    echo "  Ubuntu/Debian: sudo apt install ngrok"
    echo "  Windows: 访问 https://ngrok.com/download"
    exit 1
fi

# 检查authtoken
if ! ngrok config check &> /dev/null; then
    echo "❌ 错误: ngrok未配置authtoken"
    echo ""
    echo "请先配置ngrok:"
    echo "  1. 访问 https://ngrok.com 注册账号"
    echo "  2. 获取authtoken"
    echo "  3. 运行: ngrok config add-authtoken YOUR_AUTH_TOKEN"
    exit 1
fi

# 获取端口号
PORT=${1:-8000}

echo "创建ngrok隧道..."
echo "  本地端口: $PORT"
echo "  公网URL: 即将显示"
echo ""
echo "按 Ctrl+C 停止ngrok"
echo ""
echo "提示: 打开 http://localhost:4040 查看请求详情"
echo ""
echo "=========================================="
echo ""

# 启动ngrok
ngrok http $PORT
