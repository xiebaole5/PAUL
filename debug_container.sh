#!/bin/bash

echo "=== 天虹视频生成服务 - 容器诊断脚本 ==="
echo ""

# 检查容器状态
echo "1. 检查容器状态："
docker-compose ps
echo ""

# 查看 API 容器日志（最后 50 行）
echo "2. 查看 tnho-video-api 容器最新日志："
docker-compose logs --tail=50 tnho-video-api
echo ""

# 尝试进入容器并检查 Python 环境
echo "3. 检查容器内 Python 环境："
docker-compose exec -T tnho-video-api python --version
docker-compose exec -T tnho-video-api python -c "import sys; print('Python path:', sys.path[:3])"
echo ""

# 检查关键模块是否可导入
echo "4. 检查关键模块导入："
docker-compose exec -T tnho-video-api python -c "import langchain; print('✓ langchain OK')" 2>&1 || echo "✗ langchain failed"
docker-compose exec -T tnho-video-api python -c "import langgraph; print('✓ langgraph OK')" 2>&1 || echo "✗ langgraph failed"
docker-compose exec -T tnho-video-api python -c "import coze_workload_identity; print('✓ coze_workload_identity OK')" 2>&1 || echo "✗ coze_workload_identity failed"
docker-compose exec -T tnho-video-api python -c "import storage.memory.memory_saver; print('✓ storage.memory.memory_saver OK')" 2>&1 || echo "✗ storage.memory.memory_saver failed"
echo ""

# 检查工作目录结构
echo "5. 检查工作目录结构："
docker-compose exec -T tnho-video-api ls -la /app/
docker-compose exec -T tnho-video-api ls -la /app/src/
echo ""

# 尝试直接导入 app.py
echo "6. 尝试直接导入 app.py："
docker-compose exec -T tnho-video-api python -c "import sys; sys.path.insert(0, '/app'); sys.path.insert(0, '/app/src'); from api import app; print('✓ app import OK')" 2>&1
echo ""

# 检查环境变量
echo "7. 检查环境变量："
docker-compose exec -T tnho-video-api env | grep -E "(COZE|ARK|DB|PYTHONPATH)" || echo "未找到相关环境变量"
echo ""

echo "=== 诊断完成 ==="
