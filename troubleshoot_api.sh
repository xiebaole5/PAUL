#!/bin/bash

# API 文档打不开问题排查脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================="
echo "API 文档问题排查"
echo "========================================="
echo ""

echo -e "${BLUE}步骤 1: 检查容器状态${NC}"
echo "-------------------------------------------"
docker-compose ps
echo ""

echo -e "${BLUE}步骤 2: 检查容器日志（最后 100 行）${NC}"
echo "-------------------------------------------"
docker-compose logs --tail=100 tnho-video-api
echo ""

echo -e "${BLUE}步骤 3: 测试容器内服务${NC}"
echo "-------------------------------------------"
echo "进入容器测试..."
docker-compose exec -T tnho-video-api curl -s http://localhost:8000/health || echo "❌ 容器内健康检查失败"
echo ""

echo -e "${BLUE}步骤 4: 测试宿主机访问${NC}"
echo "-------------------------------------------"
echo "从宿主机测试..."
curl -s http://localhost:8000/health || echo "❌ 宿主机访问失败"
echo ""

echo -e "${BLUE}步骤 5: 检查端口占用${NC}"
echo "-------------------------------------------"
netstat -tlnp | grep -E "8000|80" || echo "端口检查完成"
echo ""

echo -e "${BLUE}步骤 6: 进入容器检查环境${NC}"
echo "-------------------------------------------"
echo "检查 Python 路径..."
docker-compose exec -T tnho-video-api bash -c 'echo "PYTHONPATH=$PYTHONPATH"'
echo ""

echo "检查 sys.path..."
docker-compose exec -T tnho-video-api python -c "import sys; print('\n'.join(sys.path))"
echo ""

echo "测试模块导入..."
docker-compose exec -T tnho-video-api python -c "from storage.memory.memory_saver import get_memory_saver; print('✓ 导入成功')" 2>&1 || echo "❌ 导入失败"
echo ""

echo -e "${BLUE}步骤 7: 检查文件结构${NC}"
echo "-------------------------------------------"
echo "检查 /app/src/ 目录..."
docker-compose exec -T tnho-video-api ls -la /app/src/ | head -20
echo ""

echo "检查 /app/src/storage/ 目录..."
docker-compose exec -T tnho-video-api ls -la /app/src/storage/ 2>&1 || echo "❌ storage 目录不存在"
echo ""

echo "检查 /app/src/storage/memory/ 目录..."
docker-compose exec -T tnho-video-api ls -la /app/src/storage/memory/ 2>&1 || echo "❌ memory 目录不存在"
echo ""

echo "========================================="
echo -e "${YELLOW}排查完成${NC}"
echo "========================================="
echo ""
echo "如果发现错误，请查看完整日志："
echo "  docker-compose logs -f tnho-video-api"
echo ""
echo "或进入容器手动检查："
echo "  docker-compose exec tnho-video-api /bin/bash"
