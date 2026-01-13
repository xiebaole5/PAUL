#!/bin/bash

# 在服务器上修复 agent.py 的导入语句

echo "正在修复 agent.py 导入语句..."

# 将错误的导入改为正确的导入（移除 src. 前缀）
sed -i 's/from src\.storage\.memory\.memory_saver import/from storage.memory.memory_saver import/' src/agents/agent.py

echo "✓ agent.py 已修复"

# 验证修改
echo ""
echo "验证导入语句："
grep "from.*memory_saver" src/agents/agent.py

echo ""
echo "✓ 修复完成！现在可以重新构建镜像："
echo ""
echo "  docker-compose down"
echo "  docker-compose build --no-cache"
echo "  docker-compose up -d"
