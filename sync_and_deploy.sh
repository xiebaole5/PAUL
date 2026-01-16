#!/bin/bash
# 服务器一键同步和部署脚本
# 在服务器47.110.72.148上执行

set -e  # 遇到错误立即退出

echo "=== 开始同步和部署 ==="
echo ""

# 第一步：停止旧服务
echo "[1/6] 停止旧服务..."
pkill -9 -f uvicorn 2>/dev/null || true
sleep 3
echo "✅ 旧服务已停止"
echo ""

# 第二步：进入项目目录
echo "[2/6] 进入项目目录..."
cd /workspace/projects
echo "当前目录: $(pwd)"
echo ""

# 第三步：拉取最新代码
echo "[3/6] 拉取最新代码..."
if [ -d ".git" ]; then
    git fetch origin
    git reset --hard origin/main
    git clean -fd
    echo "✅ 代码已更新"
else
    echo "⚠️  不是一个Git仓库，尝试克隆..."
    git clone https://github.com/xiebaole5/PAUL.git . 2>/dev/null || echo "仓库已存在"
fi
echo ""

# 第四步：查看最新文件
echo "[4/6] 检查最新文件..."
ls -la *.sh *.md 2>/dev/null | head -10 || echo "没有找到脚本文件"
echo ""

# 第五步：添加执行权限
echo "[5/6] 添加执行权限..."
chmod +x *.sh 2>/dev/null || true
echo "✅ 执行权限已设置"
echo ""

# 第六步：启动服务
echo "[6/6] 启动服务..."
if [ -f "start_service_v2.sh" ]; then
    bash start_service_v2.sh
else
    echo "⚠️  start_service_v2.sh 不存在，使用手动启动..."
    export COZE_WORKSPACE_PATH=/workspace/projects
    export PYTHONPATH=/workspace/projects/src:$PYTHONPATH
    nohup python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

    sleep 5

    if ps aux | grep -v grep | grep -q "uvicorn.*src.main:app"; then
        echo "✅ 服务已启动"
        curl http://localhost:8080/health
    else
        echo "❌ 服务启动失败"
        tail -30 /tmp/fastapi.log
        exit 1
    fi
fi

echo ""
echo "=== 部署完成 ==="
echo ""
echo "验证命令："
echo "  curl http://localhost:8080/health"
echo "  curl http://47.110.72.148/health (Nginx配置后)"
