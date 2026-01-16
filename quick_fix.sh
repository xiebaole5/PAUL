#!/bin/bash
# 快速修复脚本 - 在服务器上执行

echo "=== FastAPI 服务快速修复 ==="
echo ""

# 1. 查看实际启动日志
echo "[1] 查看最新启动日志（最后50行）："
tail -50 /tmp/fastapi.log
echo ""

# 2. 测试不同接口
echo "[2] 测试所有可用接口："
echo "   测试 / 根路径："
curl -s http://localhost:8080/ | head -5
echo ""
echo "   测试 /health："
curl -s http://localhost:8080/health
echo ""
echo "   测试 /docs（Swagger文档）："
curl -s http://localhost:8080/docs | head -5
echo ""

# 3. 检查进程详细信息
echo "[3] 检查进程详细信息："
ps aux | grep uvicorn | grep -v grep
echo ""

# 4. 检查Python模块
echo "[4] 检查模块路径："
python3 -c "import sys; print('\n'.join(sys.path))"
echo ""
