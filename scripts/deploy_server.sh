#!/bin/bash
# 天虹紧固件小程序后端部署脚本
# 用于在服务器上部署和更新后端代码

set -e  # 遇到错误立即退出

echo "========================================"
echo "天虹紧固件小程序后端部署脚本"
echo "========================================"

# 1. 查找项目目录
echo ""
echo "步骤 1: 查找项目目录..."
POSSIBLE_PATHS=(
    "/root/PAUL"
    "/home/PAUL"
    "/opt/PAUL"
    "/var/www/PAUL"
    "/workspace/PAUL"
)

PROJECT_DIR=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ] && [ -d "$path/.git" ]; then
        PROJECT_DIR="$path"
        break
    fi
done

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ 未找到项目目录！"
    echo ""
    echo "请手动指定项目目录，然后运行："
    echo "cd /你的/项目/目录"
    echo "bash scripts/deploy_server.sh"
    exit 1
fi

echo "✅ 找到项目目录: $PROJECT_DIR"

# 2. 进入项目目录
cd "$PROJECT_DIR"
echo "✅ 已进入项目目录: $(pwd)"

# 3. 拉取最新代码
echo ""
echo "步骤 2: 拉取最新代码..."
git fetch origin main
git reset --hard origin/main
echo "✅ 代码已更新到最新版本"

# 4. 停止旧服务
echo ""
echo "步骤 3: 停止旧服务..."
pkill -f "uvicorn src.main:app" || true
sleep 2
echo "✅ 旧服务已停止"

# 5. 检查 Python 虚拟环境
echo ""
echo "步骤 4: 检查 Python 环境..."

if [ -d "venv" ]; then
    echo "✅ 找到虚拟环境: venv"
    source venv/bin/activate
    echo "✅ 已激活虚拟环境"
else
    echo "⚠️  未找到虚拟环境，使用系统 Python"
    echo "   当前 Python: $(which python3)"
    echo "   版本: $(python3 --version)"
fi

# 6. 安装依赖（如果需要）
echo ""
echo "步骤 5: 检查依赖..."
if [ -f "requirements.txt" ]; then
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "📦 安装依赖到虚拟环境..."
        pip install -r requirements.txt --quiet
    else
        echo "📦 安装依赖到系统（使用 --break-system-packages）..."
        pip install -r requirements.txt --break-system-packages --quiet
    fi
    echo "✅ 依赖已安装"
else
    echo "⚠️  未找到 requirements.txt，跳过依赖安装"
fi

# 7. 启动新服务
echo ""
echo "步骤 6: 启动后端服务..."

# 设置 PYTHONPATH
export PYTHONPATH="$PROJECT_DIR:$PROJECT_DIR/src"

# 启动服务
if [ -n "$VIRTUAL_ENV" ]; then
    # 使用虚拟环境
    nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/miniprogram_backend.log 2>&1 &
else
    # 使用系统 Python
    nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/miniprogram_backend.log 2>&1 &
fi

BACKEND_PID=$!
echo "✅ 后端服务已启动 (PID: $BACKEND_PID)"

# 8. 等待服务启动
echo ""
echo "步骤 7: 等待服务启动..."
sleep 5

# 9. 健康检查
echo ""
echo "步骤 8: 健康检查..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ 服务启动成功！"
        echo ""
        echo "========================================"
        echo "部署完成！"
        echo "========================================"
        echo "服务地址: http://0.0.0.0:8080"
        echo "健康检查: http://localhost:8080/health"
        echo "日志文件: /tmp/miniprogram_backend.log"
        echo "进程 PID: $BACKEND_PID"
        echo ""
        echo "查看日志："
        echo "  tail -f /tmp/miniprogram_backend.log"
        echo ""
        echo "停止服务："
        echo "  pkill -f 'uvicorn src.main:app'"
        echo "========================================"
        exit 0
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "⏳ 等待服务启动... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

# 启动失败
echo ""
echo "❌ 服务启动失败！"
echo ""
echo "查看错误日志："
echo "  tail -100 /tmp/miniprogram_backend.log"
echo ""
echo "检查进程："
echo "  ps aux | grep uvicorn"
exit 1
