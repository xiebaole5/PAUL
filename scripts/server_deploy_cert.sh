#!/bin/bash

# 服务器端 Cloudflare Origin Certificate 快速部署脚本
#
# 使用方法：
#   1. 在本地生成证书（使用 generate_cloudflare_cert.py）
#   2. 将证书文件复制到服务器的 /tmp 目录
#   3. SSH 登录服务器
#   4. 执行本脚本：bash server_deploy_cert.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
CERT_SOURCE="/tmp/cloudflare-origin.crt"
KEY_SOURCE="/tmp/cloudflare-origin.key"
CERT_DEST="/etc/nginx/ssl/tnho-origin.crt"
KEY_DEST="/etc/nginx/ssl/tnho-origin.key"
BACKUP_DIR="/etc/nginx/ssl/backup"

# 显示欢迎信息
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cloudflare Origin Certificate 部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} 请使用 root 用户执行此脚本"
    exit 1
fi

# 检查证书文件是否存在
if [ ! -f "$CERT_SOURCE" ]; then
    echo -e "${RED}[ERROR]${NC} 证书文件不存在：$CERT_SOURCE"
    echo ""
    echo "请先将证书文件复制到服务器的 /tmp 目录："
    echo "  scp cloudflare-origin.crt root@$(hostname -I | awk '{print $1}'):/tmp/"
    echo "  scp cloudflare-origin.key root@$(hostname -I | awk '{print $1}'):/tmp/"
    exit 1
fi

if [ ! -f "$KEY_SOURCE" ]; then
    echo -e "${RED}[ERROR]${NC} 私钥文件不存在：$KEY_SOURCE"
    echo ""
    echo "请先将私钥文件复制到服务器的 /tmp 目录："
    echo "  scp cloudflare-origin.key root@$(hostname -I | awk '{print $1}'):/tmp/"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份现有证书
echo -e "${BLUE}[INFO]${NC} 备份现有证书..."
if [ -f "$CERT_DEST" ]; then
    cp "$CERT_DEST" "$BACKUP_DIR/tnho-origin.crt.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${GREEN}[SUCCESS]${NC} 已备份现有证书"
fi

if [ -f "$KEY_DEST" ]; then
    cp "$KEY_DEST" "$BACKUP_DIR/tnho-origin.key.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${GREEN}[SUCCESS]${NC} 已备份现有私钥"
fi

# 复制新证书
echo -e "${BLUE}[INFO]${NC} 部署新证书..."
cp "$CERT_SOURCE" "$CERT_DEST"
cp "$KEY_SOURCE" "$KEY_DEST"
echo -e "${GREEN}[SUCCESS]${NC} 证书部署完成"

# 设置权限
echo -e "${BLUE}[INFO]${NC} 设置证书权限..."
chmod 644 "$CERT_DEST"
chmod 600 "$KEY_DEST"
echo -e "${GREEN}[SUCCESS]${NC} 权限设置完成"

# 验证证书
echo -e "${BLUE}[INFO]${NC} 验证证书信息..."
openssl x509 -in "$CERT_DEST" -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /'
echo ""

# 测试 Nginx 配置
echo -e "${BLUE}[INFO]${NC} 测试 Nginx 配置..."
if nginx -t; then
    echo -e "${GREEN}[SUCCESS]${NC} Nginx 配置测试通过"
else
    echo -e "${RED}[ERROR]${NC} Nginx 配置测试失败"
    echo -e "${YELLOW}[WARN]${NC} 正在回滚到备份证书..."
    if [ -f "$BACKUP_DIR/tnho-origin.crt.backup."* ]; then
        cp "$BACKUP_DIR/tnho-origin.crt.backup."* "$CERT_DEST"
        cp "$BACKUP_DIR/tnho-origin.key.backup."* "$KEY_DEST"
        echo -e "${GREEN}[SUCCESS]${NC} 已回滚到备份证书"
    fi
    exit 1
fi

# 重启 Nginx
echo -e "${BLUE}[INFO]${NC} 重启 Nginx..."
nginx -s reload
sleep 2

# 检查 Nginx 状态
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}[SUCCESS]${NC} Nginx 重启成功"
else
    echo -e "${RED}[ERROR]${NC} Nginx 重启失败"
    echo -e "${YELLOW}[WARN]${NC} 正在回滚到备份证书..."
    if [ -f "$BACKUP_DIR/tnho-origin.crt.backup."* ]; then
        cp "$BACKUP_DIR/tnho-origin.crt.backup."* "$CERT_DEST"
        cp "$BACKUP_DIR/tnho-origin.key.backup."* "$KEY_DEST"
        nginx -s reload
        echo -e "${GREEN}[SUCCESS]${NC} 已回滚到备份证书"
    fi
    exit 1
fi

# 测试 HTTPS 访问
echo -e "${BLUE}[INFO]${NC} 测试 HTTPS 访问..."
if curl -sk -o /dev/null -w "%{http_code}" https://localhost/health | grep -q "200"; then
    echo -e "${GREEN}[SUCCESS]${NC} HTTPS 访问正常"
else
    echo -e "${YELLOW}[WARN]${NC} HTTPS 访问可能有问题，请手动验证"
fi

# 完成
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "下一步操作："
echo "  1. 测试 HTTPS 访问："
echo "     curl -I https://tnho-fasteners.com"
echo ""
echo "  2. 检查 Cloudflare SSL 设置："
echo "     - 登录 https://dash.cloudflare.com/"
echo "     - 选择 tnho-fasteners.com 域名"
echo "     - 进入 SSL/TLS -> Overview"
echo "     - 确保模式为 'Full' 或 'Full (strict)'"
echo ""
echo "  3. 验证证书："
echo "     ./scripts/verify_cert.sh tnho-fasteners.com"
echo ""
echo "  4. 测试小程序："
echo "     - 打开微信开发者工具"
echo "     - 刷新小程序"
echo "     - 应该可以正常访问 API 了"
echo ""
echo "备份文件位置："
echo "  $BACKUP_DIR/"
echo ""
