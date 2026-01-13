# 快速修复和重启命令

# 步骤 1：停止现有容器
docker-compose down

# 步骤 2：清理旧镜像（可选，但推荐）
docker image rm tnho-video-generator_api 2>/dev/null || true

# 步骤 3：重新构建镜像（使用修改后的 Dockerfile）
docker-compose build --no-cache

# 步骤 4：启动服务
docker-compose up -d

# 步骤 5：等待 30 秒让服务完全启动
sleep 30

# 步骤 6：查看容器状态
docker-compose ps

# 步骤 7：查看日志（最后 50 行）
docker-compose logs --tail=50

# 步骤 8：测试健康检查
curl http://localhost:8000/health

# 步骤 9：如果健康检查失败，查看详细日志
# docker-compose logs -f tnho-video-api
