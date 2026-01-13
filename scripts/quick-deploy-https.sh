#!/bin/bash

# HTTPS 快速部署脚本
# 使用 Let's Encrypt 免费证书
# 使用方法: sudo bash scripts/quick-deploy-https.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=========================================="
echo "HTTPS 快速部署向导"
echo "=========================================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 步骤 1: 输入域名
echo -e "${YELLOW}步骤 1/5: 输入域名${NC}"
echo ""
echo "请输入已备案的域名，例如："
echo "  - tnho-video.com"
echo "  - video.tnho.com"
echo ""
read -p "请输入域名: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}域名不能为空${NC}"
    exit 1
fi

# 验证域名格式
if [[ ! $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo -e "${RED}域名格式不正确${NC}"
    exit 1
fi

echo ""
echo "你输入的域名是: ${GREEN}$DOMAIN${NC}"
read -p "确认吗？(y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "配置已取消"
    exit 1
fi

# 步骤 2: 安装 Certbot
echo ""
echo -e "${YELLOW}步骤 2/5: 安装 Certbot${NC}"
echo "正在更新软件源..."
apt update -qq

echo "正在安装 Certbot..."
apt install -y certbot python3-certbot-nginx

if command -v certbot &> /dev/null; then
    echo -e "${GREEN}Certbot 安装成功${NC}"
else
    echo -e "${RED}Certbot 安装失败${NC}"
    exit 1
fi

# 步骤 3: 获取 SSL 证书
echo ""
echo -e "${YELLOW}步骤 3/5: 获取 SSL 证书${NC}"
echo ""
echo "正在申请 SSL 证书..."
echo "域名: $DOMAIN"
echo ""

# 检查 80 端口是否被占用
if netstat -tuln | grep -q ':80 '; then
    echo -e "${YELLOW}警告：80 端口已被占用${NC}"
    echo "尝试停止占用 80 端口的进程..."

    # 尝试停止 Nginx 容器
    if docker ps | grep -q "tnho-nginx"; then
        echo "停止 Nginx 容器..."
        docker-compose stop nginx
        sleep 2
    fi
fi

# 获取证书
echo "正在获取证书..."
certbot certonly --standalone \
    -d $DOMAIN \
    --email admin@$DOMAIN \
    --agree-tos \
    --non-interactive \
    --force-renewal

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SSL 证书获取成功！${NC}"
    echo "证书位置: /etc/letsencrypt/live/$DOMAIN/"
else
    echo -e "${RED}SSL 证书获取失败${NC}"
    echo ""
    echo "可能的原因："
    echo "  1. 域名未正确解析到服务器 IP"
    echo "  2. 80 端口被防火墙阻止"
    echo "  3. 域名未备案"
    echo ""
    echo "请检查后重试"
    exit 1
fi

# 步骤 4: 更新配置文件
echo ""
echo -e "${YELLOW}步骤 4/5: 更新配置文件${NC}"

# 备份原配置
cp nginx/nginx.conf nginx/nginx.conf.bak

# 更新 Nginx 配置
echo "更新 Nginx 配置..."
sed -i "s/your-domain.com/$DOMAIN/g" nginx/nginx.conf

# 确保使用 Let's Encrypt 证书路径
sed -i 's|# ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;|ssl_certificate /etc/letsencrypt/live/'$DOMAIN'/fullchain.pem;|' nginx/nginx.conf
sed -i 's|# ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;|ssl_certificate_key /etc/letsencrypt/live/'$DOMAIN'/privkey.pem;|' nginx/nginx.conf

# 注释掉手动证书配置
sed -i 's|ssl_certificate /etc/nginx/ssl/cert.pem;|# ssl_certificate /etc/nginx/ssl/cert.pem;|' nginx/nginx.conf
sed -i 's|ssl_certificate_key /etc/nginx/ssl/key.pem;|# ssl_certificate_key /etc/nginx/ssl/key.pem;|' nginx/nginx.conf

echo -e "${GREEN}Nginx 配置已更新${NC}"

# 更新小程序配置
echo "更新小程序 API 配置..."
API_URL="https://$DOMAIN"

# 更新 app.js
if grep -q "http://47.110.72.148" miniprogram/app.js; then
    sed -i "s|http://47.110.72.148|$API_URL|g" miniprogram/app.js
fi

# 更新 index.js
if grep -q "http://47.110.72.148" miniprogram/pages/index/index.js; then
    sed -i "s|http://47.110.72.148|$API_URL|g" miniprogram/pages/index/index.js
fi

# 更新 result.js
if grep -q "http://47.110.72.148" miniprogram/pages/result/result.js; then
    sed -i "s|http://47.110.72.148|$API_URL|g" miniprogram/pages/result/result.js
fi

echo -e "${GREEN}小程序配置已更新${NC}"

# 步骤 5: 重启服务
echo ""
echo -e "${YELLOW}步骤 5/5: 重启服务${NC}"

# 启动 Docker Compose
echo "重启 Docker Compose..."
docker-compose up -d nginx

# 等待服务启动
echo "等待服务启动..."
sleep 5

# 测试 HTTPS 连接
echo ""
echo "测试 HTTPS 连接..."
if curl -s -I https://$DOMAIN | grep -q "HTTP"; then
    echo -e "${GREEN}HTTPS 连接测试成功！${NC}"
else
    echo -e "${YELLOW}HTTPS 连接测试失败，请手动检查${NC}"
fi

# 完成
echo ""
echo -e "${GREEN}=========================================="
echo "部署完成！"
echo "==========================================${NC}"
echo ""
echo "域名: ${GREEN}$DOMAIN${NC}"
echo "HTTPS 地址: ${GREEN}https://$DOMAIN${NC}"
echo "API 地址: ${GREEN}https://$DOMAIN/api${NC}"
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "1. 测试 HTTPS 访问:"
echo "   curl https://$DOMAIN/api/health"
echo ""
echo "2. 配置微信小程序服务器域名:"
echo "   登录微信公众平台 → 开发设置 → 服务器域名"
echo "   添加: https://$DOMAIN"
echo ""
echo "3. 在微信开发者工具中重新编译小程序"
echo ""
echo -e "${YELLOW}证书自动续期：${NC}"
echo "已设置每月 1 号凌晨 3 点自动续期证书"
echo "如需修改: sudo crontab -e"
echo ""
echo -e "${GREEN}备份文件：${NC}"
echo "  - nginx/nginx.conf.bak (原配置)"
echo ""
