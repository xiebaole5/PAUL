#!/bin/bash
#
# Let's Encrypt 证书配置脚本
# 用途：为 tnho-fasteners.com 申请并配置 HTTPS 证书
#

set -e

echo "========================================="
echo "Let's Encrypt 证书配置脚本"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误：请使用 root 用户执行此脚本${NC}"
    exit 1
fi

# 域名配置
DOMAIN="tnho-fasteners.com"
WWW_DOMAIN="www.tnho-fasteners.com"
EMAIL="xiebaole5@gmail.com"

echo -e "${YELLOW}域名: ${DOMAIN}${NC}"
echo -e "${YELLOW}邮箱: ${EMAIL}${NC}"
echo ""

# 检查域名是否解析到当前服务器
echo "检查域名解析..."
CURRENT_IP=$(curl -s -4 ifconfig.me)
DOMAIN_IP=$(dig +short ${DOMAIN} | head -n 1)

echo "当前服务器IP: ${CURRENT_IP}"
echo "域名解析IP: ${DOMAIN_IP}"

if [ "$CURRENT_IP" != "$DOMAIN_IP" ]; then
    echo -e "${YELLOW}警告：域名解析的IP (${DOMAIN_IP}) 与当前服务器IP (${CURRENT_IP}) 不一致${NC}"
    echo -e "${YELLOW}这可能是正常的（如果使用了 Cloudflare CDN），但请确认 DNS 配置正确${NC}"
    echo ""
    read -p "是否继续？(y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消"
        exit 1
    fi
fi

# 检查端口 80 是否被占用
echo ""
echo "检查端口 80..."
if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    echo -e "${YELLOW}警告：端口 80 已被占用${NC}"
    echo -e "${YELLOW}Let's Encrypt 需要使用端口 80 进行域名验证${NC}"
    echo ""
    echo "正在尝试释放端口 80..."

    # 尝试停止 Nginx
    if pgrep -x nginx > /dev/null; then
        echo "停止 Nginx 服务..."
        pkill nginx || killall nginx || true
        sleep 2
    fi

    # 检查端口是否仍被占用
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        echo -e "${RED}错误：无法释放端口 80，请手动停止占用端口的程序${NC}"
        echo "运行以下命令查看占用端口 80 的进程："
        echo "  netstat -tlnp | grep :80"
        exit 1
    fi
fi

# 安装 Certbot
echo ""
echo "安装 Certbot..."
apt-get update
apt-get install -y certbot

# 申请证书
echo ""
echo "========================================="
echo "申请 Let's Encrypt 证书"
echo "========================================="
echo "域名: ${DOMAIN}, ${WWW_DOMAIN}"
echo "邮箱: ${EMAIL}"
echo ""

# 使用 standalone 模式申请证书
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email ${EMAIL} \
    -d ${DOMAIN} \
    -d ${WWW_DOMAIN} \
    --preferred-challenges http

# 检查证书是否申请成功
if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    echo -e "${RED}错误：证书申请失败${NC}"
    echo "请检查："
    echo "1. 域名 DNS 是否正确解析"
    echo "2. 服务器防火墙是否开放端口 80"
    echo "3. 网络连接是否正常"
    exit 1
fi

echo -e "${GREEN}证书申请成功！${NC}"
echo ""
echo "证书文件位置："
echo "  证书链: /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
echo "  私钥:   /etc/letsencrypt/live/${DOMAIN}/privkey.pem"

# 备份现有的 Nginx 配置
echo ""
echo "备份现有的 Nginx 配置..."
if [ -f "/etc/nginx/sites-available/tnho-https.conf" ]; then
    cp /etc/nginx/sites-available/tnho-https.conf /etc/nginx/sites-available/tnho-https.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "已备份到: /etc/nginx/sites-available/tnho-https.conf.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 创建新的 Nginx HTTPS 配置
echo ""
echo "创建 Nginx HTTPS 配置..."
cat > /etc/nginx/sites-available/tnho-https.conf << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # HTTP 到 HTTPS 重定向
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Let's Encrypt 证书路径
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # SSL 会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS (可选，增加安全性)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 其他安全头部
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # 日志
    access_log /var/log/nginx/tnho-https-access.log;
    error_log /var/log/nginx/tnho-https-error.log;

    # 反向代理到 FastAPI 应用
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # 健康检查接口
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        access_log off;
    }

    # 静态文件（如果有）
    location /static {
        alias /workspace/projects/assets;
        expires 30d;
    }
}
EOF

echo "Nginx 配置已创建"

# 创建符号链接（如果不存在）
if [ ! -L "/etc/nginx/sites-enabled/tnho-https.conf" ]; then
    ln -sf /etc/nginx/sites-available/tnho-https.conf /etc/nginx/sites-enabled/tnho-https.conf
    echo "已创建符号链接"
fi

# 测试 Nginx 配置
echo ""
echo "测试 Nginx 配置..."
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Nginx 配置测试通过${NC}"
else
    echo -e "${RED}Nginx 配置测试失败${NC}"
    echo "请检查配置文件：/etc/nginx/sites-available/tnho-https.conf"
    exit 1
fi

# 启动 Nginx
echo ""
echo "启动 Nginx..."
pkill nginx || true
sleep 2
nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Nginx 启动成功${NC}"
else
    echo -e "${RED}Nginx 启动失败${NC}"
    exit 1
fi

# 设置证书自动续期
echo ""
echo "设置证书自动续期..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && nginx -s reload") | crontab -
echo "已设置每天凌晨 3 点自动续期证书"

# 完成
echo ""
echo "========================================="
echo -e "${GREEN}配置完成！${NC}"
echo "========================================="
echo ""
echo "证书信息："
echo "  域名: ${DOMAIN}, ${WWW_DOMAIN}"
echo "  有效期: 90 天（自动续期）"
echo "  证书路径: /etc/letsencrypt/live/${DOMAIN}/"
echo ""
echo "访问地址："
echo "  HTTP:  http://${DOMAIN}/"
echo "  HTTPS: https://${DOMAIN}/"
echo ""
echo "下一步操作："
echo "1. 在 Cloudflare 控制台配置 SSL/TLS 模式为 Full"
echo "2. 访问 https://${DOMAIN}/ 验证 HTTPS 是否正常"
echo "3. 测试小程序连接"
echo ""
echo -e "${GREEN}所有配置已完成！${NC}"
