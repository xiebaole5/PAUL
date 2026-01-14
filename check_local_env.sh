#!/bin/bash

echo "=========================================="
echo "检查本地开发环境"
echo "=========================================="
echo ""

# 检查Python
echo "1. 检查Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "   ✅ Python已安装: $PYTHON_VERSION"
else
    echo "   ❌ Python未安装，请先安装Python 3.12+"
    exit 1
fi

# 检查pip
echo ""
echo "2. 检查pip..."
if command -v pip3 &> /dev/null; then
    echo "   ✅ pip已安装"
else
    echo "   ⚠️  pip未找到，尝试使用pip"
fi

# 检查FastAPI
echo ""
echo "3. 检查FastAPI依赖..."
if python3 -c "import fastapi" 2>/dev/null; then
    FASTAPI_VERSION=$(python3 -c "import fastapi; print(fastapi.__version__)")
    echo "   ✅ FastAPI已安装: v$FASTAPI_VERSION"
else
    echo "   ❌ FastAPI未安装"
    echo ""
    echo "   安装命令:"
    echo "   pip3 install fastapi uvicorn pydantic python-dotenv"
fi

# 检查Uvicorn
echo ""
echo "4. 检查Uvicorn..."
if python3 -c "import uvicorn" 2>/dev/null; then
    UVICORN_VERSION=$(python3 -c "import uvicorn; print(uvicorn.__version__)")
    echo "   ✅ Uvicorn已安装: v$UVICORN_VERSION"
else
    echo "   ❌ Uvicorn未安装"
fi

# 检查ngrok
echo ""
echo "5. 检查ngrok..."
if command -v ngrok &> /dev/null; then
    NGROK_VERSION=$(ngrok version)
    echo "   ✅ ngrok已安装: $NGROK_VERSION"

    # 检查authtoken
    if ngrok config check &> /dev/null; then
        echo "   ✅ ngrok已配置authtoken"
    else
        echo "   ⚠️  ngrok未配置authtoken"
        echo ""
        echo "   配置步骤:"
        echo "   1. 访问 https://ngrok.com 注册账号"
        echo "   2. 获取authtoken"
        echo "   3. 运行: ngrok config add-authtoken YOUR_AUTH_TOKEN"
    fi
else
    echo "   ❌ ngrok未安装"
    echo ""
    echo "   安装方法:"
    echo "   macOS: brew install ngrok"
    echo "   Ubuntu/Debian: sudo apt install ngrok"
    echo "   Windows: 访问 https://ngrok.com/download 下载"
fi

# 检查端口占用
echo ""
echo "6. 检查端口占用..."
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "   ⚠️  8000端口已被占用"
    echo "   进程信息:"
    lsof -i :8000
else
    echo "   ✅ 8000端口可用"
fi

if lsof -Pi :4040 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "   ⚠️  4040端口已被占用 (ngrok面板)"
else
    echo "   ✅ 4040端口可用 (ngrok面板)"
fi

# 总结
echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
echo ""
echo "下一步:"
echo "  1. 如果缺少依赖，请安装"
echo "  2. 运行: bash start_local.sh"
echo ""
