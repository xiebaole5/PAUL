#!/bin/bash

echo "=========================================="
echo "启动本地FastAPI服务"
echo "=========================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "app.py" ] || [ ! -d "src" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    echo "   当前目录: $(pwd)"
    echo "   应该包含: app.py 和 src/ 目录"
    exit 1
fi

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: Python未安装"
    exit 1
fi

# 检查端口占用
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  警告: 8000端口已被占用"
    echo ""
    read -p "是否停止占用8000端口的进程? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "正在停止进程..."
        lsof -ti :8000 | xargs kill -9
        sleep 1
    else
        echo "使用备用端口8001..."
        PORT=8001
    fi
fi

if [ -z "$PORT" ]; then
    PORT=8000
fi

echo "启动FastAPI服务..."
echo "  端口: $PORT"
echo "  地址: http://localhost:$PORT"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""
echo "=========================================="
echo ""

# 加载环境变量
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ 已加载 .env 文件"
fi

# 启动服务
python3 -m uvicorn app:app --host 0.0.0.0 --port $PORT --reload
