#!/bin/bash

# 服务器项目路径诊断脚本

echo "====================================="
echo "正在检查服务器上的项目目录..."
echo "====================================="
echo ""

# 1. 检查用户主目录
echo "1. 检查 /root 下的项目："
ls -la /root/ | grep -E "tnho|video|api" || echo "  未找到相关目录"
echo ""

# 2. 检查常见的项目路径
echo "2. 检查常见项目路径："
paths=(
  "/root/tnho-video-api"
  "/root/tnho-video"
  "/root/video-api"
  "/home/tnho-video-api"
  "/opt/tnho-video-api"
  "/app"
  "/var/www/tnho"
)

for path in "${paths[@]}"; do
  if [ -d "$path" ]; then
    echo "  ✓ 找到目录: $path"
    ls -la "$path" | head -5
  fi
done
echo ""

# 3. 搜索包含 Dockerfile 或 docker-compose.yml 的目录
echo "3. 搜索 Docker 项目："
echo "  查找 docker-compose.yml："
find /root -maxdepth 4 -name "docker-compose.yml" 2>/dev/null || echo "  未找到 docker-compose.yml"
echo ""
echo "  查找 Dockerfile："
find /root -maxdepth 4 -name "Dockerfile" 2>/dev/null || echo "  未找到 Dockerfile"
echo ""

# 4. 搜索运行中的Docker容器
echo "4. 检查运行中的 Docker 容器："
if command -v docker &> /dev/null; then
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" || echo "  没有运行中的容器"
  echo ""
  echo "  所有容器（包括停止的）："
  docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
else
  echo "  Docker 未安装或不可用"
fi
echo ""

# 5. 检查Nginx配置（如果是通过Nginx部署）
echo "5. 检查 Nginx 配置："
if command -v nginx &> /dev/null; then
  nginx -t 2>&1 | grep -E "conf|test" || echo "  未找到Nginx配置"
  echo ""
  echo "  Nginx 站点配置："
  ls -la /etc/nginx/sites-enabled/ 2>/dev/null || ls -la /etc/nginx/conf.d/ 2>/dev/null || echo "  未找到站点配置"
else
  echo "  Nginx 未安装"
fi
echo ""

echo "====================================="
echo "诊断完成"
echo "====================================="
