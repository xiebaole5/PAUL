#!/bin/bash
# 完整部署脚本 - 一键克隆、安装依赖、启动服务
# 在服务器47.110.72.148上执行

set -e

echo "=========================================="
echo "  天虹紧固件 FastAPI 服务完整部署"
echo "=========================================="
echo ""

# 第一步：停止旧服务
echo "[1/7] 停止旧服务..."
pkill -9 -f uvicorn 2>/dev/null || true
sleep 2
echo "✅ 旧服务已停止"
echo ""

# 第二步：备份旧项目（如果存在）
echo "[2/7] 备份旧项目..."
cd /workspace
if [ -d "projects" ]; then
    BACKUP_DIR="projects_backup_$(date +%Y%m%d_%H%M%S)"
    echo "备份当前项目到: $BACKUP_DIR"
    mv projects "$BACKUP_DIR"
fi
echo "✅ 备份完成"
echo ""

# 第三步：克隆仓库
echo "[3/7] 克隆最新代码..."
git clone https://github.com/xiebaole5/PAUL.git projects
cd /workspace/projects
echo "✅ 仓库克隆完成"
echo ""

# 第四步：检查Python环境
echo "[4/7] 检查Python环境..."
python3 --version
pip3 --version
echo ""

# 第五步：安装依赖
echo "[5/7] 安装Python依赖..."
echo "这可能需要5-10分钟，请耐心等待..."

if [ -f "requirements.txt" ]; then
    # 升级pip
    pip3 install --upgrade pip

    # 安装依赖
    pip3 install -r requirements.txt
    echo ""
    echo "✅ 依赖安装完成"
else
    echo "❌ 错误：找不到 requirements.txt"
    exit 1
fi

# 验证关键依赖
echo ""
echo "验证关键依赖..."
python3 -c "
import sys
missing = []
try:
    import langchain
    print('✅ langchain')
except ImportError:
    missing.append('langchain')

try:
    import langgraph
    print('✅ langgraph')
except ImportError:
    missing.append('langgraph')

try:
    import fastapi
    print('✅ fastapi')
except ImportError:
    missing.append('fastapi')

try:
    import moviepy
    print('✅ moviepy')
except ImportError:
    missing.append('moviepy')

if missing:
    print(f'❌ 缺少依赖: {missing}')
    sys.exit(1)
else:
    print('✅ 所有关键依赖已安装'
"

# 第六步：启动服务
echo ""
echo "[6/7] 启动FastAPI服务..."

# 设置环境变量
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH

# 启动服务
if [ -f "start_service_v2.sh" ]; then
    chmod +x start_service_v2.sh
    bash start_service_v2.sh
else
    # 手动启动
    nohup python3 -m uvicorn src.main:app \
      --host 0.0.0.0 \
      --port 8080 \
      --log-level info \
      > /tmp/fastapi.log 2>&1 &

    sleep 5

    if ps aux | grep -v grep | grep -q "uvicorn.*src.main:app"; then
        echo "✅ 服务已启动"
    else
        echo "❌ 服务启动失败"
        echo ""
        echo "错误日志："
        tail -50 /tmp/fastapi.log
        exit 1
    fi
fi

# 第七步：验证服务
echo ""
echo "[7/7] 验证服务..."
echo "测试根路径："
curl -s http://localhost:8080/ | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/
echo ""

echo "测试健康检查："
curl -s http://localhost:8080/health
echo ""

echo "测试API接口："
curl -s -X POST http://localhost:8080/api/generate-script \
  -H "Content-Type: application/json" \
  -d '{"product_name":"螺母","product_image_url":"http://test.com/img.jpg","usage_scenario":"建筑","theme_direction":"高品质"}' | head -100
echo ""

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo ""
echo "服务信息："
echo "  端口: 8080"
echo "  健康检查: http://localhost:8080/health"
echo "  API文档: http://localhost:8080/docs"
echo "  日志文件: /tmp/fastapi.log"
echo ""
echo "管理命令："
echo "  查看日志: tail -f /tmp/fastapi.log"
echo "  重启服务: bash start_service_v2.sh"
echo "  停止服务: pkill -9 uvicorn"
echo ""
