#!/bin/bash
# 服务器端检查和配置脚本

echo "======================================"
echo "步骤 1: 检查项目目录"
echo "======================================"

if [ -d "/root/tnho-video-api" ]; then
    echo "✅ 项目目录存在: /root/tnho-video-api"
    cd /root/tnho-video-api
    ls -la
else
    echo "❌ 项目目录不存在: /root/tnho-video-api"
    echo "正在查找项目目录..."
    find /root -name "docker-compose.yml" -type f 2>/dev/null | head -5
    exit 1
fi

echo ""
echo "======================================"
echo "步骤 2: 检查 Docker 服务"
echo "======================================"
docker ps

echo ""
echo "======================================"
echo "步骤 3: 检查后端服务是否运行"
echo "======================================"
BACKEND_RUNNING=$(docker ps --filter "name=tnho" --format "{{.Names}}")
if [ -n "$BACKEND_RUNNING" ]; then
    echo "✅ 后端服务正在运行"
    echo "$BACKEND_RUNNING"
else
    echo "⚠️  后端服务未运行，尝试启动..."
    docker-compose up -d
fi

echo ""
echo "======================================"
echo "步骤 4: 测试后端 API"
echo "======================================"
curl -s http://localhost:8000/health || echo "⚠️  后端 API 无响应"

echo ""
echo "======================================"
echo "步骤 5: 配置 Nginx"
echo "======================================"

# 创建 Nginx 配置文件
sudo tee /etc/nginx/conf.d/tnho-api.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com 47.110.72.148;

    # 最大上传大小
    client_max_body_size 10M;

    # API 代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    # 静态文件
    location /assets/ {
        proxy_pass http://127.0.0.1:8000/assets/;
    }

    # 根路径
    location / {
        proxy_pass http://127.0.0.1:8000/;
    }
}
EOF

echo "✅ Nginx 配置文件已创建"

# 测试 Nginx 配置
echo ""
echo "======================================"
echo "步骤 6: 测试 Nginx 配置"
echo "======================================"
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置正确"
else
    echo "❌ Nginx 配置有误"
    exit 1
fi

echo ""
echo "======================================"
echo "步骤 7: 重载 Nginx 服务"
echo "======================================"
sudo systemctl reload nginx
sudo systemctl status nginx | head -10

echo ""
echo "======================================"
echo "步骤 8: 测试通过 Nginx 访问"
echo "======================================"
echo "测试本地访问:"
curl -s http://localhost/health && echo ""

echo ""
echo "测试公网访问:"
curl -s http://47.110.72.148/health && echo ""

echo ""
echo "测试域名访问:"
curl -s http://tnho-fasteners.com/health && echo ""

echo ""
echo "======================================"
echo "配置完成！"
echo "======================================"
echo ""
echo "访问地址："
echo "  - HTTP: http://tnho-fasteners.com"
echo "  - HTTP: http://47.110.72.148"
echo ""
echo "测试 API："
echo "  curl http://tnho-fasteners.com/health"
echo ""
echo "======================================"
