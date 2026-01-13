#!/bin/bash

echo "=== 天虹视频生成服务 - 一键修复脚本 ==="
echo ""

# 检查容器状态
echo "1. 检查容器状态："
docker-compose ps

echo ""
echo "2. 查看 API 容器最新日志（最近 100 行）："
docker-compose logs --tail=100 tnho-video-api 2>&1 | grep -A 5 -B 5 -i "error\|exception\|traceback" || echo "未发现明显错误"

echo ""
echo "3. 尝试修复常见问题..."

# 创建临时修复脚本
docker-compose exec -T tnho-video-api bash -c '
# 安装缺失的包（如果有）
pip install --quiet coze-workload-identity 2>&1 | head -5

# 检查 sys.path
echo "Python sys.path:"
python -c "import sys; [print(p) for p in sys.path]"

echo ""
echo "测试关键模块导入："
python -c "import langchain; print(\"✓ langchain\")" 2>&1 || echo "✗ langchain failed"
python -c "import langgraph; print(\"✓ langgraph\")" 2>&1 || echo "✗ langgraph failed"
python -c "import storage.memory.memory_saver; print(\"✓ storage.memory.memory_saver\")" 2>&1 || echo "✗ storage.memory.memory_saver failed"
python -c "from agents.agent import build_agent; print(\"✓ build_agent\")" 2>&1 || echo "✗ build_agent failed"
'

echo ""
echo "4. 重启容器..."
docker-compose restart tnho-video-api

echo ""
echo "等待 15 秒..."
sleep 15

echo ""
echo "5. 检查容器状态："
docker-compose ps

echo ""
echo "6. 测试健康检查："
HEALTH=$(curl -s http://localhost:8000/health 2>&1)
echo "健康检查响应: $HEALTH"

echo ""
echo "=== 修复完成 ==="
echo "如果服务仍未正常，请运行: docker-compose logs -f tnho-video-api"
