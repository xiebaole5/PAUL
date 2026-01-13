#!/bin/bash
# Cloudflare Origin Certificate 服务器端生成脚本
# 用途：直接在服务器上生成并部署 SSL 证书

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
CERT_DIR="/etc/nginx/ssl"
BACKUP_DIR="/etc/nginx/ssl/backup"
WORK_DIR="/tmp/cloudflare_cert"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cloudflare 证书自动生成和部署${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 root 用户运行此脚本${NC}"
    exit 1
fi

# 检查必要的命令
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}错误: 未找到 Python 3，请先安装${NC}"
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    echo -e "${RED}错误: 未找到 Nginx，请先安装${NC}"
    exit 1
fi

# 安装依赖
echo -e "\n${YELLOW}1. 检查依赖...${NC}"
if ! python3 -c "import requests" 2>/dev/null; then
    echo -e "${YELLOW}安装 requests 库...${NC}"
    pip3 install requests
fi
echo -e "${GREEN}✓ 依赖检查通过${NC}"

# 交互式获取配置
echo -e "\n${YELLOW}2. 配置信息${NC}"

read -p "请输入 Cloudflare API Token: " API_TOKEN
if [ -z "$API_TOKEN" ]; then
    echo -e "${RED}错误: API Token 不能为空${NC}"
    exit 1
fi

read -p "请输入域名 (默认: tnho-fasteners.com): " DOMAIN
DOMAIN=${DOMAIN:-"tnho-fasteners.com"}

read -p "请输入 Cloudflare Zone ID (留空自动查找): " ZONE_ID

# 创建工作目录
echo -e "\n${YELLOW}3. 准备工作环境...${NC}"
mkdir -p "${WORK_DIR}"
mkdir -p "${CERT_DIR}"
mkdir -p "${BACKUP_DIR}"

# 备份现有证书
if [ -f "${CERT_DIR}/cloudflare-origin.pem" ]; then
    echo -e "${YELLOW}备份现有证书...${NC}"
    cp -f "${CERT_DIR}/cloudflare-origin.pem" "${BACKUP_DIR}/cert_${TIMESTAMP}.pem"
    cp -f "${CERT_DIR}/cloudflare-origin-key.pem" "${BACKUP_DIR}/key_${TIMESTAMP}.pem"
    echo -e "${GREEN}✓ 现有证书已备份${NC}"
fi

# 创建 Python 脚本
cat > "${WORK_DIR}/generate_cert.py" << 'PYTHON_EOF'
#!/usr/bin/env python3
import requests
import sys
import json

API_TOKEN = sys.argv[1]
ZONE_ID = sys.argv[2]
DOMAIN = sys.argv[3]

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# 如果没有 Zone ID，自动查找
if not ZONE_ID:
    print("正在获取 Zone ID...")
    resp = requests.get("https://api.cloudflare.com/client/v4/zones", headers=headers)
    if resp.status_code == 200:
        data = resp.json()
        zones = data.get("result", [])
        for zone in zones:
            if DOMAIN in zone.get("name", ""):
                ZONE_ID = zone["id"]
                print(f"找到 Zone: {zone['name']} (ID: {ZONE_ID})")
                break

if not ZONE_ID:
    print("错误: 未找到 Zone ID")
    sys.exit(1)

# 生成证书
payload = {
    "hostnames": [DOMAIN, f"*.{DOMAIN}", f"www.{DOMAIN}"],
    "requested_validity": 5475,
    "request_type": "origin-ecc",
    "certificate_authority": "cloudflare"
}

print(f"正在生成证书 (域名: {DOMAIN})...")
resp = requests.post(
    f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/origin/ca/certificate",
    headers=headers,
    json=payload
)

if resp.status_code == 200:
    data = resp.json()
    if data.get("success"):
        result = data.get("result", {})
        print("✓ 证书生成成功")
        print(result.get("certificate"), file=open("/tmp/cloudflare_cert/cert.pem", "w"))
        print(result.get("private_key"), file=open("/tmp/cloudflare_cert/key.pem", "w"))
        sys.exit(0)

print(f"错误: {resp.text}")
sys.exit(1)
PYTHON_EOF

# 运行证书生成脚本
echo -e "\n${YELLOW}4. 生成证书...${NC}"
if python3 "${WORK_DIR}/generate_cert.py" "$API_TOKEN" "$ZONE_ID" "$DOMAIN"; then
    echo -e "${GREEN}✓ 证书生成成功${NC}"
else
    echo -e "${RED}错误: 证书生成失败${NC}"
    echo -e "${YELLOW}请检查:${NC}"
    echo -e "  1. API Token 是否正确"
    echo -e "  2. API Token 是否有 SSL and Certificates - Edit 权限"
    echo -e "  3. 域名是否已添加到 Cloudflare"
    exit 1
fi

# 移动证书文件
echo -e "\n${YELLOW}5. 部署证书...${NC}"
mv "${WORK_DIR}/cert.pem" "${CERT_DIR}/cloudflare-origin.pem"
mv "${WORK_DIR}/key.pem" "${CERT_DIR}/cloudflare-origin-key.pem"
chmod 644 "${CERT_DIR}/cloudflare-origin.pem"
chmod 600 "${CERT_DIR}/cloudflare-origin-key.pem"
echo -e "${GREEN}✓ 证书已部署${NC}"

# 验证证书和私钥
echo -e "\n${YELLOW}6. 验证证书...${NC}"
CERT_MOD=$(openssl x509 -noout -modulus -in "${CERT_DIR}/cloudflare-origin.pem" 2>/dev/null | openssl md5)
KEY_MOD=$(openssl rsa -noout -modulus -in "${CERT_DIR}/cloudflare-origin-key.pem" 2>/dev/null | openssl md5)

if [ "${CERT_MOD}" = "${KEY_MOD}" ]; then
    echo -e "${GREEN}✓ 证书验证通过${NC}"
else
    echo -e "${RED}错误: 证书和私钥不匹配${NC}"
    exit 1
fi

# 检查 Nginx 配置
echo -e "\n${YELLOW}7. 检查 Nginx 配置...${NC}"
if ! grep -q "cloudflare-origin.pem" /etc/nginx/nginx.conf; then
    echo -e "${YELLOW}注意: Nginx 配置中未找到 Cloudflare 证书配置${NC}"
    echo -e "${YELLOW}请确保 nginx.conf 中包含以下配置:${NC}"
    echo -e "  ssl_certificate /etc/nginx/ssl/cloudflare-origin.pem;"
    echo -e "  ssl_certificate_key /etc/nginx/ssl/cloudflare-origin-key.pem;"
fi

# 测试 Nginx
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
else
    echo -e "${RED}错误: Nginx 配置测试失败${NC}"
    echo -e "${YELLOW}请检查 Nginx 配置文件${NC}"
    exit 1
fi

# 重载 Nginx
echo -e "\n${YELLOW}8. 重载 Nginx...${NC}"
systemctl reload nginx
echo -e "${GREEN}✓ Nginx 已重载${NC}"

# 清理临时文件
rm -rf "${WORK_DIR}"

# 显示证书信息
echo -e "\n${YELLOW}证书信息:${NC}"
echo -e "  域名: ${DOMAIN}"
echo -e "  证书文件: ${CERT_DIR}/cloudflare-origin.pem"
echo -e "  私钥文件: ${CERT_DIR}/cloudflare-origin-key.pem"
echo -e "  有效期: 15 年"

# 显示下一步操作
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 证书生成和部署成功！${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}下一步操作:${NC}"
echo -e "  1. 配置 Cloudflare DNS${NC}"
echo -e "     - A 记录: ${DOMAIN} -> $(curl -s ifconfig.me)"
echo -e "     - 代理状态: 已代理（橙色云）"
echo -e "  2. 配置 Cloudflare SSL/TLS${NC}"
echo -e "     - 加密模式: Full (strict)"
echo -e "     - Always Use HTTPS: 启用"
echo -e "  3. 测试访问${NC}"
echo -e "     - curl -I https://${DOMAIN}"
echo -e "     - 浏览器访问 https://${DOMAIN}"

echo -e "\n${GREEN}========================================${NC}"
