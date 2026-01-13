#!/bin/bash
# 服务器端完整部署脚本 - 需要先上传代码压缩包

set -e  # 遇到错误立即退出

echo "======================================"
echo "天虹紧固件视频生成 API - 服务器部署脚本"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检查参数
if [ "$1" != "--skip-backup" ]; then
    print_warning "使用 --skip-backup 跳过备份"
fi

# 1. 检查压缩包是否存在
print_warning "步骤 1: 检查代码压缩包"
if [ ! -f "/root/tnho-latest.tar.gz" ]; then
    print_error "代码压缩包不存在：/root/tnho-latest.tar.gz"
    echo "请先从本地环境执行："
    echo "  cd /workspace/projects"
    echo "  tar -czf tnho-latest.tar.gz --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' ."
    echo "  scp tnho-latest.tar.gz root@47.110.72.148:/root/"
    exit 1
fi
print_success "代码压缩包已找到"

# 2. 备份旧版本（如果存在）
echo ""
print_warning "步骤 2: 备份旧版本"
if [ -d "/root/tnho-video-api" ] && [ "$1" != "--skip-backup" ]; then
    BACKUP_DIR="/root/tnho-video-api.backup.$(date +%Y%m%d_%H%M%S)"
    mv /root/tnho-video-api "$BACKUP_DIR"
    print_success "旧版本已备份到：$BACKUP_DIR"
else
    print_warning "跳过备份"
fi

# 3. 创建项目目录并解压
echo ""
print_warning "步骤 3: 解压新代码"
mkdir -p /root/tnho-video-api
cd /root/tnho-video-api
tar -xzf /root/tnho-latest.tar.gz
print_success "代码已解压到 /root/tnho-video-api"

# 4. 检查并创建 .env 文件
echo ""
print_warning "步骤 4: 检查配置文件"
if [ ! -f ".env" ]; then
    print_warning ".env 文件不存在，创建默认配置"
    cat > .env << 'ENV_EOF'
# 火山方舟 API 配置
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 数据库配置
PGDATABASE_URL=postgresql://postgres:postgres@db:5432/tnho_video

# 外部访问 URL
EXTERNAL_BASE_URL=https://tnho-fasteners.com

# 工作目录
COZE_WORKSPACE_PATH=/app
COZE_INTEGRATION_MODEL_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
COZE_WORKLOAD_IDENTITY_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ENV_EOF
    print_success ".env 文件已创建"
else
    print_success ".env 文件已存在"
fi

# 5. 停止并删除旧容器
echo ""
print_warning "步骤 5: 停止旧容器"
cd /root/tnho-video-api
docker-compose down 2>/dev/null || true
print_success "旧容器已停止"

# 6. 重新构建镜像
echo ""
print_warning "步骤 6: 构建 Docker 镜像"
echo "这可能需要几分钟时间..."
docker-compose build --no-cache
print_success "Docker 镜像构建完成"

# 7. 启动容器
echo ""
print_warning "步骤 7: 启动服务"
docker-compose up -d
print_success "容器已启动"

# 8. 等待服务就绪
echo ""
print_warning "步骤 8: 等待服务就绪"
sleep 10

# 9. 检查服务状态
echo ""
print_warning "步骤 9: 检查服务状态"
docker ps | grep tnho

if [ $? -eq 0 ]; then
    print_success "容器运行正常"
else
    print_error "容器启动失败，查看日志："
    docker logs tnho-video-api --tail 50
    exit 1
fi

# 10. 测试 API
echo ""
print_warning "步骤 10: 测试 API"
sleep 5

echo -n "测试 /health 端点... "
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
echo "$HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q "ok\|healthy"; then
    print_success "健康检查通过"
else
    print_error "健康检查失败"
fi

echo -n "测试 /docs 端点... "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs
if [ $? -eq 200 ]; then
    print_success "API 文档可访问"
else
    print_warning "API 文档访问异常"
fi

# 11. 配置 Nginx
echo ""
print_warning "步骤 11: 配置 Nginx"

# 检查 Nginx 是否已安装
if ! command -v nginx &> /dev/null; then
    echo "Nginx 未安装，正在安装..."
    apt-get update && apt-get install -y nginx
fi

# 创建 Nginx 配置
sudo tee /etc/nginx/conf.d/tnho-api.conf > /dev/null << 'NGINX_CONF'
server {
    listen 80;
    server_name tnho-fasteners.com 47.110.72.148;

    client_max_body_size 10M;

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
    }

    location /assets/ {
        proxy_pass http://127.0.0.1:8000/assets/;
        proxy_set_header Host $host;
    }

    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
    }

    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
    }

    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_CONF

print_success "Nginx 配置已创建"

# 测试并重载 Nginx
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    print_success "Nginx 已重载"
else
    print_error "Nginx 配置有误"
    exit 1
fi

# 12. 最终验证
echo ""
print_warning "步骤 12: 最终验证"
echo ""
echo "======================================"
echo "测试本地访问："
curl -s http://localhost/health
echo ""
echo "测试公网访问："
curl -s http://47.110.72.148/health
echo ""
echo "测试域名访问："
curl -s http://tnho-fasteners.com/health
echo ""
echo "======================================"

# 13. 显示部署信息
echo ""
print_success "======================================"
print_success "部署完成！"
print_success "======================================"
echo ""
echo "服务信息："
echo "  - 后端地址: http://127.0.0.1:8000"
echo "  - 公网地址: http://47.110.72.148"
echo "  - 域名地址: http://tnho-fasteners.com"
echo ""
echo "API 文档："
echo "  - Swagger UI: http://tnho-fasteners.com/docs"
echo "  - OpenAPI: http://tnho-fasteners.com/openapi.json"
echo ""
echo "常用命令："
echo "  - 查看日志: docker logs -f tnho-video-api"
echo "  - 重启服务: docker-compose restart"
echo "  - 停止服务: docker-compose down"
echo "  - 查看状态: docker ps | grep tnho"
echo ""
echo "======================================"
