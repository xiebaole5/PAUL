#!/bin/bash
# 依赖安装脚本 - 使用 --break-system-packages 选项
# 在服务器47.110.72.148上执行

set -e

echo "=== 安装Python依赖 ==="
echo ""

# 检查Python版本
echo "[1] 检查Python版本..."
python3 --version
echo ""

# 检查pip版本
echo "[2] 检查pip版本..."
pip3 --version
echo ""

# 升级pip（使用 --break-system-packages）
echo "[3] 升级pip..."
pip3 install --upgrade pip --break-system-packages
echo ""

# 安装依赖（使用 --break-system-packages）
echo "[4] 安装项目依赖..."
echo "这可能需要几分钟时间，请耐心等待..."

if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --break-system-packages
    echo ""
    echo "✅ 依赖安装完成"
else
    echo "❌ 错误：找不到 requirements.txt 文件"
    exit 1
fi

echo ""
echo "[5] 验证关键依赖..."
python3 -c "
try:
    import langchain
    print('✅ langchain 已安装')
except ImportError:
    print('❌ langchain 未安装')

try:
    import langgraph
    print('✅ langgraph 已安装')
except ImportError:
    print('❌ langgraph 未安装')

try:
    import fastapi
    print('✅ fastapi 已安装')
except ImportError:
    print('❌ fastapi 未安装')

try:
    import moviepy
    print('✅ moviepy 已安装')
except ImportError:
    print('❌ moviepy 未安装')
"

echo ""
echo "=== 依赖安装完成 ==="
