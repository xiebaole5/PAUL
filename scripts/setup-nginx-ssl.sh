#!/bin/bash
# Nginx SSL配置快速脚本
# 用于快速配置Nginx使用Let's Encrypt证书

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  Nginx SSL配置脚本"
echo "  天虹紧固件小程序"
echo "=========================================="
echo ""

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用sudo运行此脚本"
    exit 1
fi

# 1. 检查证书是否存在
echo "📋 步骤 1/7: 检查SSL证书..."
if [ -f "/etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem" ]; then
    echo "✅ SSL证书已存在"
else
    echo "❌ SSL证书不存在，请先运行certbot申请证书"
    exit 1
fi

# 2. 安装Nginx
echo ""
echo "📋 步骤 2/7: 安装Nginx..."
if command -v nginx &> /dev/null; then
    echo "✅ Nginx已安装"
else
    apt update
    apt install nginx -y
    echo "✅ Nginx安装成功"
fi

# 3. 创建配置文件
echo ""
echo "📋 步骤 3/7: 创建Nginx配置文件..."
cat > /etc/nginx/sites-available/tnho-fasteners.com << 'EOF'
# HTTP重定向到HTTPS
server {
    listen 80;
    server_name tnho-fasteners.com;

    # Let's Encrypt验证使用的路径
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # 其他请求重定向到HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS虚拟主机
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com;

    # SSL证书配置
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # SSL协议和加密套件
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;

    # SSL会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS（可选，增强安全性）
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 日志配置
    access_log /var/log/nginx/tnho-fasteners-access.log;
    error_log /var/log/nginx/tnho-fasteners-error.log;

    # 客户端最大上传大小
    client_max_body_size 10M;

    # API代理
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # 静态文件服务
    location /assets/ {
        alias /app/assets/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
echo "✅ 配置文件创建成功"

# 4. 创建certbot目录
echo ""
echo "📋 步骤 4/7: 创建certbot目录..."
mkdir -p /var/www/certbot
chown -R www-data:www-data /var/www/certbot
echo "✅ certbot目录创建成功"

# 5. 启用站点配置
echo ""
echo "📋 步骤 5/7: 启用站点配置..."
ln -sf /etc/nginx/sites-available/tnho-fasteners.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
echo "✅ 站点配置已启用"

# 6. 测试Nginx配置
echo ""
echo "📋 步骤 6/7: 测试Nginx配置..."
if nginx -t; then
    echo "✅ Nginx配置测试通过"
else
    echo "❌ Nginx配置测试失败"
    exit 1
fi

# 7. 启动Nginx
echo ""
echo "📋 步骤 7/7: 启动Nginx..."
systemctl restart nginx
systemctl enable nginx
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
echo "   https://tnho-fasteners.com/health"
echo ""
echo "📊 Nginx状态："
echo "   sudo systemctl status nginx"
echo ""
echo "📝 查看日志："
echo "   sudo tail -f /var/log/nginx/tnho-fasteners-access.log"
echo "   sudo tail -f /var/log/nginx/tnho-fasteners-error.log"
echo ""
echo "⚠️  下一步："
echo "   1. 配置Cloudflare SSL/TLS模式为Full"
echo "   2. 在小程序后台配置服务器域名"
echo "   3. 更新小程序API地址为HTTPS"
echo ""
echo "详细文档："
echo "   - Nginx配置: docs/nginx-ssl-config.md"
echo "   - Cloudflare配置: docs/cloudflare-config.md"
echo "   - 发布指南: docs/发布指南.md"
echo ""
echo "=========================================="
echo ""
