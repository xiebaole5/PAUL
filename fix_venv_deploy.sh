#!/bin/bash

set -e

echo "=== 天虹紧固件 FastAPI 服务部署（使用虚拟环境） ==="

# 第一步：停止旧服务
echo "[1/6] 停止旧服务..."
pkill -9 uvicorn 2>/dev/null || true
pkill -9 python3 2>/dev/null || true
sleep 2

# 第二步：创建虚拟环境
echo "[2/6] 创建 Python 虚拟环境..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ 虚拟环境已创建"
else
    echo "✓ 虚拟环境已存在"
fi

# 第三步：激活虚拟环境并安装依赖
echo "[3/6] 激活虚拟环境并安装依赖..."
source venv/bin/activate

# 升级 pip
pip install --upgrade pip

# 安装依赖
pip install -r requirements.txt

echo "✓ 依赖安装完成"

# 第四步：创建启动脚本（使用虚拟环境）
echo "[4/6] 创建启动脚本..."
cat > start_with_venv.sh << 'EOF'
#!/bin/bash
set -e

# 停止旧服务
pkill -9 uvicorn 2>/dev/null || true
pkill -9 python3 2>/dev/null || true
sleep 2

# 激活虚拟环境
cd /workspace/projects
source venv/bin/activate

# 设置环境变量
export COZE_WORKSPACE_PATH=/workspace/projects
export PYTHONPATH=/workspace/projects/src:$PYTHONPATH

# 启动 FastAPI 服务（8080端口）
nohup python -m uvicorn src.main:app --host 0.0.0.0 --port 8080 --log-level info > /tmp/fastapi.log 2>&1 &

# 等待服务启动
sleep 5

# 验证服务
echo "=== 服务状态检查 ==="
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✓ 服务启动成功"
    curl -s http://localhost:8080/health
else
    echo "❌ 服务启动失败，查看日志："
    tail -50 /tmp/fastapi.log
fi
EOF

chmod +x start_with_venv.sh
echo "✓ 启动脚本已创建: start_with_venv.sh"

# 第五步：立即启动服务
echo "[5/6] 启动服务..."
bash start_with_venv.sh

# 第六步：显示后续操作提示
echo ""
echo "=== 部署完成 ==="
echo ""
echo "后续操作："
echo "1. 重启服务: bash start_with_venv.sh"
echo "2. 查看日志: tail -f /tmp/fastapi.log"
echo "3. 停止服务: pkill -9 uvicorn"
echo "4. 健康检查: curl http://localhost:8080/health"
echo "5. 查看API文档: http://localhost:8080/docs"
echo ""
echo "Nginx 配置："
echo "将 80 端口流量转发到 8080 端口"
echo ""
