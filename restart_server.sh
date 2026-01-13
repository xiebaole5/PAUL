#!/bin/bash

# 天虹紧固件视频生成服务重启脚本
# 用途：在服务器上重新启动 Docker 容器，应用代码修改
# 域名：tnho-fasteners.com

echo "=========================================="
echo "天虹紧固件视频生成服务重启"
echo "=========================================="
echo "域名：tnho-fasteners.com"
echo "文本模型：doubao-1.8"
echo "视频模型：doubao-seedance-1-5-pro"
echo "=========================================="

# 切换到项目目录
cd /opt/tnho-video-generator || exit 1
echo "✓ 已切换到项目目录"

# 停止并删除容器
echo ""
echo "正在停止容器..."
docker stop tnho-video-api tnho-nginx 2>/dev/null || true
echo "✓ 已停止容器"

echo ""
echo "正在删除容器..."
docker rm tnho-video-api tnho-nginx 2>/dev/null || true
echo "✓ 已删除容器"

# 等待端口释放
sleep 3

# 重新启动容器
echo ""
echo "正在重新启动容器..."
docker-compose up -d
echo "✓ 容器启动命令已执行"

# 等待服务启动
echo ""
echo "等待服务启动（15秒）..."
sleep 15

# 查看服务状态
echo ""
echo "=========================================="
echo "容器状态："
echo "=========================================="
docker ps -a --filter "name=tnho"

# 查看最新日志
echo ""
echo "=========================================="
echo "最新日志（tnho-video-api）："
echo "=========================================="
docker logs --tail 50 tnho-video-api

# 健康检查
echo ""
echo "=========================================="
echo "健康检查："
echo "=========================================="
sleep 5
curl -s http://localhost:8000/health || echo "健康检查失败"

echo ""
echo "=========================================="
echo "重启完成！"
echo "=========================================="
echo "API 服务: http://47.110.72.148:8000"
echo "API 文档: http://47.110.72.148:8000/docs"
echo "健康检查: http://47.110.72.148:8000/health"
echo "=========================================="
