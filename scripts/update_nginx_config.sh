#!/bin/bash
# 更新 Nginx 配置脚本 - 用于服务器端

echo "======================================"
echo "更新 Nginx 配置"
echo "======================================"

# 创建 Nginx 配置文件（正确版本）
sudo tee /etc/nginx/conf.d/tnho-api.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com 47.110.72.148;

    # 最大上传大小
    client_max_body_size 10M;

    # API 代理 - 注意这里去掉了末尾的斜杠
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置（视频生成可能需要较长时间）
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;

        # WebSocket 支持（如果需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
    }

    # 静态文件
    location /assets/ {
        proxy_pass http://127.0.0.1:8000/assets/;
        proxy_set_header Host $host;
    }

    # API 文档
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
    }

    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
    }

    # 根路径
    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✅ Nginx 配置文件已更新"

# 测试配置
echo ""
echo "======================================"
echo "测试 Nginx 配置"
echo "======================================"
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx 配置正确"
    echo ""
    echo "重载 Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx 已重载"
else
    echo "❌ Nginx 配置有误"
    exit 1
fi

echo ""
echo "======================================"
echo "配置完成！"
echo "======================================"
