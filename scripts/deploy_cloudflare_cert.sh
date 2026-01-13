#!/bin/bash
# Cloudflare Origin Certificate 部署脚本
# 用途：在服务器上快速部署 SSL 证书

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
CERT_DIR="/etc/nginx/ssl"
CERT_FILE="${CERT_DIR}/cloudflare-origin.pem"
KEY_FILE="${CERT_DIR}/cloudflare-origin-key.pem"
BACKUP_DIR="/etc/nginx/ssl/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cloudflare SSL 证书部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 root 用户运行此脚本${NC}"
    echo "使用方法: sudo $0"
    exit 1
fi

# 检查 Nginx 是否已安装
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}错误: 未找到 Nginx，请先安装 Nginx${NC}"
    exit 1
fi

# 创建证书目录
echo -e "\n${YELLOW}1. 创建证书目录...${NC}"
mkdir -p "${CERT_DIR}"
mkdir -p "${BACKUP_DIR}"
echo -e "${GREEN}✓ 证书目录已创建: ${CERT_DIR}${NC}"

# 备份现有证书（如果存在）
if [ -f "${CERT_FILE}" ] || [ -f "${KEY_FILE}" ]; then
    echo -e "\n${YELLOW}2. 备份现有证书...${NC}"
    cp -f "${CERT_FILE}" "${BACKUP_DIR}/cert_${TIMESTAMP}.pem" 2>/dev/null || true
    cp -f "${KEY_FILE}" "${BACKUP_DIR}/key_${TIMESTAMP}.pem" 2>/dev/null || true
    echo -e "${GREEN}✓ 现有证书已备份到: ${BACKUP_DIR}${NC}"
fi

# 交互式输入证书内容
echo -e "\n${YELLOW}3. 输入证书内容${NC}"
echo -e "${YELLOW}请粘贴 Cloudflare Origin Certificate (PEM 格式)${NC}"
echo -e "${YELLOW}完成后按 Ctrl+D (EOF) 保存${NC}"

CERT_FILE_TMP=$(mktemp)
cat > "${CERT_FILE_TMP}" << 'CERT_EOF'
# 用户在这里粘贴证书内容
CERT_EOF

# 检查证书文件是否为空
if [ ! -s "${CERT_FILE_TMP}" ]; then
    echo -e "${RED}错误: 证书内容为空${NC}"
    rm -f "${CERT_FILE_TMP}"
    exit 1
fi

# 验证证书格式
if ! grep -q "BEGIN CERTIFICATE" "${CERT_FILE_TMP}"; then
    echo -e "${RED}错误: 证书格式无效，未找到 BEGIN CERTIFICATE${NC}"
    rm -f "${CERT_FILE_TMP}"
    exit 1
fi

# 移动证书到目标位置
mv "${CERT_FILE_TMP}" "${CERT_FILE}"
chmod 644 "${CERT_FILE}"
echo -e "${GREEN}✓ 证书已保存: ${CERT_FILE}${NC}"

# 交互式输入私钥内容
echo -e "\n${YELLOW}4. 输入私钥内容${NC}"
echo -e "${YELLOW}请粘贴私钥 (PEM 格式)${NC}"
echo -e "${YELLOW}完成后按 Ctrl+D (EOF) 保存${NC}"

KEY_FILE_TMP=$(mktemp)
cat > "${KEY_FILE_TMP}" << 'KEY_EOF'
# 用户在这里粘贴私钥内容
KEY_EOF

# 检查私钥文件是否为空
if [ ! -s "${KEY_FILE_TMP}" ]; then
    echo -e "${RED}错误: 私钥内容为空${NC}"
    rm -f "${KEY_FILE_TMP}"
    rm -f "${CERT_FILE}"
    exit 1
fi

# 验证私钥格式
if ! grep -q "BEGIN PRIVATE KEY" "${KEY_FILE_TMP}" && ! grep -q "BEGIN EC PRIVATE KEY" "${KEY_FILE_TMP}"; then
    echo -e "${RED}错误: 私钥格式无效，未找到 PRIVATE KEY 标记${NC}"
    rm -f "${KEY_FILE_TMP}"
    rm -f "${CERT_FILE}"
    exit 1
fi

# 移动私钥到目标位置
mv "${KEY_FILE_TMP}" "${KEY_FILE}"
chmod 600 "${KEY_FILE}"
echo -e "${GREEN}✓ 私钥已保存: ${KEY_FILE}${NC}"

# 验证证书和私钥匹配
echo -e "\n${YELLOW}5. 验证证书和私钥...${NC}"

CERT_MOD=$(openssl x509 -noout -modulus -in "${CERT_FILE}" 2>/dev/null | openssl md5)
KEY_MOD=$(openssl rsa -noout -modulus -in "${KEY_FILE}" 2>/dev/null | openssl md5)

if [ "${CERT_MOD}" = "${KEY_MOD}" ]; then
    echo -e "${GREEN}✓ 证书和私钥匹配${NC}"
else
    echo -e "${RED}错误: 证书和私钥不匹配！${NC}"
    echo -e "${YELLOW}请检查证书和私钥是否对应${NC}"
    exit 1
fi

# 测试 Nginx 配置
echo -e "\n${YELLOW}6. 测试 Nginx 配置...${NC}"
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
else
    echo -e "${RED}错误: Nginx 配置测试失败${NC}"
    echo -e "${YELLOW}请检查 Nginx 配置文件: /etc/nginx/nginx.conf${NC}"
    exit 1
fi

# 重载 Nginx
echo -e "\n${YELLOW}7. 重载 Nginx...${NC}"
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx 已重载${NC}"
else
    echo -e "${RED}错误: Nginx 重载失败${NC}"
    exit 1
fi

# 显示部署摘要
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 证书部署成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}证书信息:${NC}"
echo -e "  证书文件: ${CERT_FILE}"
echo -e "  私钥文件: ${KEY_FILE}"
echo -e "  权限: 644 / 600"
echo -e "  备份目录: ${BACKUP_DIR}"

echo -e "\n${YELLOW}下一步操作:${NC}"
echo -e "  1. 配置 Cloudflare DNS 指向 ${NC}"
echo -e "     - A 记录: tnho-fasteners.com -> $(curl -s ifconfig.me)"
echo -e "     - CNAME 记录: www.tnho-fasteners.com -> tnho-fasteners.com"
echo -e "  2. 在 Cloudflare SSL/TLS 设置中启用 ${NC}"
echo -e "     - 加密模式: Full (strict)"
echo -e "     - Always Use HTTPS: 启用"
echo -e "  3. 测试 HTTPS 访问${NC}"
echo -e "     - curl -I https://tnho-fasteners.com"
echo -e "     - 浏览器访问 https://tnho-fasteners.com"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
