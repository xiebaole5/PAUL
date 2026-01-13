#!/bin/bash
# 天虹紧固件小程序 - Nginx SSL配置脚本
# 直接在服务器上执行：bash nginx-setup.sh

echo "=========================================="
echo "  Nginx SSL配置脚本"
echo "  天虹紧固件小程序"
echo "=========================================="
echo ""

# 步骤1：安装Nginx
echo "步骤 1/6: 安装Nginx..."
if command -v nginx &> /dev/null; then
    echo "✅ Nginx已安装"
else
    sudo apt update
    sudo apt install nginx -y
    echo "✅ Nginx安装成功"
fi

# 步骤2：创建certbot目录
echo ""
echo "步骤 2/6: 创建certbot目录..."
sudo mkdir -p /var/www/certbot
sudo chown -R www-data:www-data /var/www/certbot
echo "✅ certbot目录创建成功"

# 步骤3：创建Nginx配置文件
echo ""
echo "步骤 3/6: 创建Nginx配置文件..."
sudo tee /etc/nginx/sites-available/tnho-fasteners.com > /dev/null << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com;

    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /assets/ {
        alias /app/assets/;
        expires 7d;
    }
}
EOF
echo "✅ Nginx配置文件创建成功"

# 步骤4：启用站点配置
echo ""
echo "步骤 4/6: 启用站点配置..."
sudo ln -sf /etc/nginx/sites-available/tnho-fasteners.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
echo "✅ 站点配置已启用"

# 步骤5：测试Nginx配置
echo ""
echo "步骤 5/6: 测试Nginx配置..."
if sudo nginx -t; then
    echo "✅ Nginx配置测试通过"
else
    echo "❌ Nginx配置测试失败，请检查配置"
    exit 1
fi

# 步骤6：启动Nginx
echo ""
echo "步骤 6/6: 启动Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx
echo "✅ Nginx启动成功"

# 完成信息
echo ""
echo "=========================================="
echo "  ✅ Nginx SSL配置完成！"
echo "=========================================="
echo ""
echo "🌐 HTTPS访问地址："
echo "   https://tnho-fasteners.com"
echo ""
echo "🔍 健康检查："
echo "   curl https://tnho-fasteners.com/health"
echo ""
echo "📊 Nginx状态："
echo "   sudo systemctl status nginx"
echo ""
echo "📝 查看日志："
echo "   sudo tail -f /var/log/nginx/error.log"
echo ""
echo "=========================================="
