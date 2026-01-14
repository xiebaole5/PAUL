#!/bin/bash

# 快速修复 Nginx 配置冲突和 SSL 证书问题
# 使用方法：sudo bash quick-fix-nginx.sh

set -e

echo "=========================================="
echo "Nginx 配置冲突和 SSL 证书快速修复脚本"
echo "=========================================="
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 第一步：诊断问题
echo -e "${YELLOW}[1/6] 诊断 Nginx 配置问题...${NC}"
echo

echo "当前启用的配置文件："
ls -la /etc/nginx/sites-enabled/

echo
echo "查找所有包含 'tnho-fasteners.com' 的配置文件："
grep -r "server_name.*tnho-fasteners.com" /etc/nginx/ 2>/dev/null || echo "未找到相关配置"

echo
read -p "按回车键继续..."
echo

# 第二步：删除重复配置
echo -e "${YELLOW}[2/6] 删除重复的 Nginx 配置...${NC}"
echo

if [ -L /etc/nginx/sites-enabled/tnho-fasteners ]; then
    echo "删除重复配置：/etc/nginx/sites-enabled/tnho-fasteners"
    sudo rm -f /etc/nginx/sites-enabled/tnho-fasteners
    echo -e "${GREEN}✓ 已删除${NC}"
else
    echo "未找到重复配置文件"
fi

echo
echo "当前启用的配置文件："
ls -la /etc/nginx/sites-enabled/

echo
read -p "按回车键继续..."
echo

# 第三步：检查证书
echo -e "${YELLOW}[3/6] 检查 Let's Encrypt SSL 证书...${NC}"
echo

if [ -d /etc/letsencrypt/live/tnho-fasteners.com ]; then
    echo -e "${GREEN}✓ 证书目录存在${NC}"
    sudo certbot certificates
else
    echo -e "${RED}✗ 证书目录不存在${NC}"
    echo
    echo "需要申请证书，请选择验证方式："
    echo "1) HTTP 验证（需要域名已解析到服务器）"
    echo "2) DNS 验证（需要添加 TXT 记录）"
    echo "3) 跳过（稍后手动申请）"
    echo
    read -p "请选择 (1/2/3): " cert_choice

    case $cert_choice in
        1)
            echo "使用 HTTP 验证申请证书..."
            sudo certbot certonly --webroot -w /var/www/certbot -d tnho-fasteners.com -d www.tnho-fasteners.com
            ;;
        2)
            echo "使用 DNS 验证申请证书..."
            sudo certbot certonly --manual --preferred-challenges dns -d tnho-fasteners.com -d www.tnho-fasteners.com
            ;;
        3)
            echo "跳过证书申请"
            ;;
        *)
            echo "无效选择，跳过证书申请"
            ;;
    esac
fi

echo
read -p "按回车键继续..."
echo

# 第四步：创建/更新 Nginx 配置
echo -e "${YELLOW}[4/6] 创建/更新 Nginx 配置文件...${NC}"
echo

NGINX_CONF="/etc/nginx/sites-available/tnho-fasteners.com"

echo "将创建以下配置文件："
echo "  $NGINX_CONF"
echo
read -p "确认继续？(y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    sudo tee $NGINX_CONF > /dev/null <<EOF
# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # Let's Encrypt 验证目录
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # 其他请求重定向到 HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS 服务器
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # SSL 协议和加密套件
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # 日志
    access_log /var/log/nginx/tnho-fasteners-access.log;
    error_log /var/log/nginx/tnho-fasteners-error.log;

    # 客户端上传大小限制
    client_max_body_size 10M;

    # 反向代理到 FastAPI
    location / {
        proxy_pass http://127.0.0.1:8000;

        # 代理头
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

    echo -e "${GREEN}✓ 配置文件已创建${NC}"
else
    echo "已取消配置文件创建"
fi

echo
read -p "按回车键继续..."
echo

# 第五步：测试并重启 Nginx
echo -e "${YELLOW}[5/6] 测试并重启 Nginx...${NC}"
echo

echo "测试 Nginx 配置..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
    echo
    echo "重新加载 Nginx..."
    sudo systemctl reload nginx
    echo -e "${GREEN}✓ Nginx 已重新加载${NC}"
else
    echo -e "${RED}✗ Nginx 配置测试失败${NC}"
    echo "请检查配置文件并手动修复"
    exit 1
fi

echo
echo "Nginx 状态："
sudo systemctl status nginx --no-pager | head -n 10

echo
read -p "按回车键继续..."
echo

# 第六步：测试 HTTPS 访问
echo -e "${YELLOW}[6/6] 测试 HTTPS 访问...${NC}"
echo

echo "测试健康检查接口..."
curl -s https://tnho-fasteners.com/health || echo -e "${RED}✗ HTTPS 访问失败${NC}"

echo
echo "检查 SSL 证书..."
echo -n "证书颁发者："
curl -vI https://tnho-fasteners.com 2>&1 | grep -i "issuer:" | head -n 1

echo
echo "=========================================="
echo -e "${GREEN}修复完成！${NC}"
echo "=========================================="
echo
echo "后续步骤："
echo "1. 配置 Cloudflare SSL/TLS 模式为 Full"
echo "2. 在小程序后台配置服务器域名"
echo "3. 测试小程序功能"
echo
echo "查看详细配置指南："
echo "  cat docs/服务器问题诊断与修复指南.md"
