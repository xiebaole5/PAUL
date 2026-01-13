#!/bin/bash

# HTTPS 配置脚本
# 域名: tnho-fasteners.com

set -e

DOMAIN="tnho-fasteners.com"
WWW_DOMAIN="www.tnho-fasteners.com"
SERVER_IP="47.110.72.148"
EMAIL="admin@${DOMAIN}"

echo "====================================="
echo "HTTPS 自动配置脚本"
echo "====================================="
echo ""
echo "域名: ${DOMAIN}"
echo "WWW域名: ${WWW_DOMAIN}"
echo "服务器IP: ${SERVER_IP}"
echo ""

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 步骤 1: 检查域名解析
echo "[STEP 1/7] 检查域名解析..."
echo "检查 ${DOMAIN} 的 DNS 解析..."
DNS_IP=$(dig +short ${DOMAIN})
if [ "${DNS_IP}" != "${SERVER_IP}" ]; then
    print_error "域名解析不正确！"
    echo "  期望IP: ${SERVER_IP}"
    echo "  实际IP: ${DNS_IP}"
    echo ""
    echo "请在域名服务商（阿里云/腾讯云）中配置 A 记录："
    echo "  主机记录: @"
    echo "  记录类型: A"
    echo "  记录值: ${SERVER_IP}"
    exit 1
fi
print_success "域名解析正确: ${DOMAIN} -> ${DNS_IP}"
echo ""

# 步骤 2: 检查 Docker 容器状态
echo "[STEP 2/7] 检查 Docker 容器状态..."
if ! docker ps | grep -q tnho-video-api; then
    print_error "后端服务未运行"
    exit 1
fi
print_success "后端服务运行正常"
echo ""

# 步骤 3: 停止 Nginx 容器（释放80端口）
echo "[STEP 3/7] 停止 Nginx 容器..."
docker-compose stop nginx
print_success "Nginx 容器已停止"
echo ""

# 步骤 4: 安装 Certbot
echo "[STEP 4/7] 检查 Certbot..."
if ! command -v certbot &> /dev/null; then
    print_info "安装 Certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot
    print_success "Certbot 安装完成"
else
    print_success "Certbot 已安装"
fi
echo ""

# 步骤 5: 申请 SSL 证书
echo "[STEP 5/7] 申请 SSL 证书..."
echo "使用 Let's Encrypt 免费证书..."
print_info "这将使用 standalone 模式（需要80端口）"
echo ""

if [ ! -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
    sudo certbot certonly --standalone \
        -d ${DOMAIN} \
        -d ${WWW_DOMAIN} \
        --email ${EMAIL} \
        --agree-tos \
        --non-interactive
    print_success "SSL 证书申请成功"
else
    print_success "SSL 证书已存在，跳过申请"
fi
echo ""

# 验证证书
print_info "验证证书..."
sudo certbot certificates
echo ""

# 步骤 6: 更新 Nginx 配置
echo "[STEP 6/7] 更新 Nginx 配置..."
print_info "创建 Nginx 配置文件..."

NGINX_CONF="/workspace/projects/nginx/nginx-https.conf"
NGINX_ENABLED="/workspace/projects/nginx/sites-enabled/${DOMAIN}"

# 创建主配置文件
sudo mkdir -p /workspace/projects/nginx/sites-enabled

cat > ${NGINX_ENABLED} << 'EOF'
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # SSL 证书配置
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 字符集
    charset utf-8;

    # 静态文件服务
    location /assets/ {
        alias /var/www/assets/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # API 代理
    location /api/ {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }

    # 健康检查
    location /health {
        proxy_pass http://api_backend/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # 根路径
    location / {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }

    # 错误页面
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}

# HTTP 自动跳转到 HTTPS
server {
    listen 80;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Let's Encrypt 验证路径
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # 其他请求跳转到 HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}
EOF

print_success "Nginx 配置文件已创建"
echo ""

# 步骤 7: 重启 Nginx
echo "[STEP 7/7] 重启 Nginx 服务..."
docker-compose restart nginx
print_success "Nginx 服务已重启"
echo ""

# 配置证书自动续期
print_info "配置证书自动续期..."
(crontab -l 2>/dev/null; echo "0 3 1 * * certbot renew --quiet && docker-compose restart nginx") | crontab -
print_success "证书自动续期任务已配置（每月1号凌晨3点）"
echo ""

# 测试 HTTPS
echo "====================================="
echo "测试 HTTPS 访问"
echo "====================================="
echo ""

sleep 3

echo "测试 HTTPS 连接..."
if curl -k -I https://${DOMAIN} | grep -q "HTTP/2"; then
    print_success "HTTPS 访问正常"
else
    print_error "HTTPS 访问失败"
    exit 1
fi

echo ""
echo "测试 API 健康检查..."
HEALTH_RESPONSE=$(curl -s -k https://${DOMAIN}/health)
if echo "${HEALTH_RESPONSE}" | grep -q "healthy\|ok"; then
    print_success "API 健康检查通过"
else
    print_error "API 健康检查失败"
fi

echo ""
echo "====================================="
echo "配置完成！"
echo "====================================="
echo ""
echo "✅ HTTPS 配置成功"
echo ""
echo "访问地址:"
echo "  HTTP:  http://${DOMAIN} (自动跳转 HTTPS)"
echo "  HTTPS: https://${DOMAIN}"
echo "  WWW:   https://${WWW_DOMAIN}"
echo ""
echo "下一步:"
echo "  1. 更新小程序 API 地址为: https://${DOMAIN}"
echo "  2. 在微信公众平台配置服务器域名"
echo ""
echo "常用命令:"
echo "  查看证书: sudo certbot certificates"
echo "  手动续期: sudo certbot renew"
echo "  重启 Nginx: docker-compose restart nginx"
echo "  查看日志: docker-compose logs nginx"
echo ""
