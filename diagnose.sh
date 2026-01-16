#!/bin/bash

echo "=== FastAPI 服务诊断工具 ==="
echo ""

# 1. 检查服务进程
echo "[1] 检查服务进程..."
ps aux | grep uvicorn | grep -v grep
if [ $? -eq 0 ]; then
    echo "✅ 服务进程运行中"
else
    echo "❌ 服务进程未运行"
fi
echo ""

# 2. 检查端口占用
echo "[2] 检查端口占用..."
netstat -tlnp 2>/dev/null | grep -E "8080|9000" || ss -tlnp 2>/dev/null | grep -E "8080|9000"
echo ""

# 3. 检查服务日志
echo "[3] 检查启动日志（最后30行）..."
if [ -f /tmp/fastapi.log ]; then
    tail -30 /tmp/fastapi.log
else
    echo "❌ 日志文件不存在"
fi
echo ""

# 4. 测试接口
echo "[4] 测试接口..."
echo "   测试根路径 /："
curl -s http://localhost:8080/ 2>&1 | head -5
echo ""
echo "   测试健康检查 /health："
curl -s http://localhost:8080/health 2>&1 | head -5
echo ""
echo "   测试 /api/test："
curl -s http://localhost:8080/api/test 2>&1 | head -5
echo ""

# 5. 检查环境变量
echo "[5] 检查环境变量..."
echo "   COZE_WORKSPACE_PATH: ${COZE_WORKSPACE_PATH:-未设置}"
echo "   PYTHONPATH: ${PYTHONPATH:-未设置}"
echo ""

# 6. 检查文件结构
echo "[6] 检查项目文件结构..."
ls -la | grep -E "(src|agents|tools)"
ls -la src/ | grep -E "(main|agents|tools)" 2>/dev/null
echo ""
