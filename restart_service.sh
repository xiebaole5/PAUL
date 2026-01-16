#!/bin/bash

echo "=== FastAPI 服务修复和重启 ==="
echo ""

# 1. 停止旧服务
echo "[1] 停止旧服务..."
pkill -9 -f "uvicorn.*main:app"
sleep 2

# 2. 检查目录结构
echo "[2] 检查目录结构..."
if [ ! -d "src/agents" ] || [ ! -d "src/tools" ]; then
    echo "❌ 错误：缺少必要的目录"
    echo "当前目录: $(pwd)"
    ls -la
    exit 1
fi

# 3. 设置环境变量
echo "[3] 设置环境变量..."
export COZE_WORKSPACE_PATH=$(pwd)
export PYTHONPATH=$(pwd)/src:$PYTHONPATH

echo "   COZE_WORKSPACE_PATH=$COZE_WORKSPACE_PATH"
echo "   PYTHONPATH=$PYTHONPATH"
echo ""

# 4. 测试模块导入
echo "[4] 测试模块导入..."
python3 -c "
import sys
sys.path.insert(0, '$COZE_WORKSPACE_PATH/src')
try:
    from agents.miniprogram_video_agent import build_agent
    print('✅ miniprogram_video_agent 导入成功')
except Exception as e:
    print(f'❌ miniprogram_video_agent 导入失败: {e}')

try:
    from tools.miniprogram_video_tool import generate_ad_script
    print('✅ miniprogram_video_tool 导入成功')
except Exception as e:
    print(f'❌ miniprogram_video_tool 导入失败: {e}')
"

if [ $? -ne 0 ]; then
    echo "❌ 模块导入失败，请检查依赖"
    exit 1
fi

echo ""

# 5. 启动服务
echo "[5] 启动 FastAPI 服务（8080端口）..."
nohup python3 -m uvicorn src.main:app \
  --host 0.0.0.0 \
  --port 8080 \
  --log-level info \
  > /tmp/fastapi.log 2>&1 &

sleep 5

# 6. 验证服务
echo ""
echo "[6] 验证服务状态..."
if ps aux | grep -v grep | grep -q "uvicorn.*src.main:app"; then
    echo "✅ 服务已启动"
    echo "   进程ID: $(ps aux | grep 'uvicorn.*src.main:app' | grep -v grep | awk '{print $2}')"
    echo "   端口: 8080"
    echo ""

    echo "[7] 测试接口..."
    echo "   根路径 /："
    curl -s http://localhost:8080/ | head -10
    echo ""
    echo "   健康检查 /health："
    curl -s http://localhost:8080/health
    echo ""
else
    echo "❌ 服务启动失败"
    echo ""
    echo "错误日志："
    tail -30 /tmp/fastapi.log
    exit 1
fi
