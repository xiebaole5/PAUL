#!/bin/bash
# 配置 Nginx 反向代理脚本

echo "开始配置 Nginx 反向代理..."

# 检查是否已安装 Nginx
if ! command -v nginx &> /dev/null; then
    echo "Nginx 未安装，请先安装 Nginx"
    exit 1
fi

# 创建 Nginx 配置文件
cat > /etc/nginx/conf.d/tnho-api.conf << 'EOF'
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

# 测试 Nginx 配置
echo "测试 Nginx 配置..."
nginx -t

if [ $? -eq 0 ]; then
    echo "配置文件语法正确，重新加载 Nginx..."
    service nginx reload
    echo "✅ Nginx 配置完成！"
else
    echo "❌ Nginx 配置有误，请检查"
    exit 1
fi

echo ""
echo "======================================"
echo "配置完成！"
echo ""
echo "访问地址："
echo "  - HTTP: http://tnho-fasteners.com"
echo "  - HTTP: http://47.110.72.148"
echo ""
echo "测试命令："
echo "curl http://tnho-fasteners.com/health"
echo "curl http://47.110.72.148/health"
echo "======================================"
