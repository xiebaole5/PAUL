#!/bin/bash

# 图片上传问题诊断脚本
# 使用方法: bash scripts/diagnose-upload.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "图片上传问题诊断"
echo "=========================================="
echo ""

API_URL="http://47.110.72.148"

# 检查 1: 后端服务状态
echo -e "${YELLOW}检查 1: 后端服务状态${NC}"
HEALTH_CHECK=$(curl -s "$API_URL/api/health")
if [ "$?" = "0" ]; then
    echo -e "${GREEN}✓ 后端服务运行正常${NC}"
    echo "响应: $HEALTH_CHECK"
else
    echo -e "${RED}✗ 后端服务异常${NC}"
fi
echo ""

# 检查 2: 上传目录
echo -e "${YELLOW}检查 2: 上传目录权限${NC}"
UPLOAD_DIR="/workspace/projects/assets/uploads"
if [ -d "$UPLOAD_DIR" ]; then
    PERMS=$(stat -c "%a" "$UPLOAD_DIR")
    OWNER=$(stat -c "%U:%G" "$UPLOAD_DIR")
    echo -e "${GREEN}✓ 上传目录存在${NC}"
    echo "路径: $UPLOAD_DIR"
    echo "权限: $PERMS"
    echo "所有者: $OWNER"
else
    echo -e "${RED}✗ 上传目录不存在${NC}"
    echo "正在创建..."
    mkdir -p "$UPLOAD_DIR"
    chmod 755 "$UPLOAD_DIR"
    echo -e "${GREEN}✓ 已创建上传目录${NC}"
fi
echo ""

# 检查 3: Nginx 配置
echo -e "${YELLOW}检查 3: Nginx 配置${NC}"
if grep -q "client_max_body_size" nginx/nginx.conf; then
    MAX_SIZE=$(grep "client_max_body_size" nginx/nginx.conf | awk '{print $2}')
    echo -e "${GREEN}✓ Nginx 文件大小限制已配置${NC}"
    echo "限制大小: $MAX_SIZE"
else
    echo -e "${RED}✗ Nginx 文件大小限制未配置${NC}"
fi

if grep -q "location /assets/" nginx/nginx.conf; then
    echo -e "${GREEN}✓ Nginx 静态文件路径已配置${NC}"
else
    echo -e "${RED}✗ Nginx 静态文件路径未配置${NC}"
fi
echo ""

# 检查 4: 后端代码配置
echo -e "${YELLOW}检查 4: 后端代码配置${NC}"
if grep -q "EXTERNAL_BASE_URL" src/api/app.py; then
    echo -e "${GREEN}✓ 后端代码已配置外部 URL${NC}"
else
    echo -e "${RED}✗ 后端代码未配置外部 URL${NC}"
fi

if grep -q "client_max_body_size" src/api/app.py; then
    echo -e "${GREEN}✓ FastAPI 文件大小限制已配置${NC}"
else
    echo -e "${YELLOW}! FastAPI 文件大小限制未配置（使用默认 1MB）${NC}"
fi
echo ""

# 检查 5: 环境变量
echo -e "${YELLOW}检查 5: 环境变量${NC}"
if grep -q "EXTERNAL_BASE_URL" docker-compose.yml; then
    echo -e "${GREEN}✓ Docker Compose 已配置 EXTERNAL_BASE_URL${NC}"
else
    echo -e "${RED}✗ Docker Compose 未配置 EXTERNAL_BASE_URL${NC}"
fi
echo ""

# 检查 6: 小程序配置
echo -e "${YELLOW}检查 6: 小程序 API 地址配置${NC}"
if grep -q "apiUrl: 'http://47.110.72.148'" miniprogram/app.js; then
    echo -e "${GREEN}✓ 小程序 API 地址已配置（开发环境）${NC}"
elif grep -q "apiUrl: 'https://" miniprogram/app.js; then
    echo -e "${GREEN}✓ 小程序 API 地址已配置（生产环境）${NC}"
else
    echo -e "${RED}✗ 小程序 API 地址未配置${NC}"
fi
echo ""

# 常见问题提示
echo -e "${YELLOW}常见问题排查：${NC}"
echo ""
echo "如果上传失败，请检查："
echo ""
echo "1. 微信开发者工具中是否勾选'不校验合法域名'"
echo "   路径: 详情 → 本地设置 → 不校验合法域名"
echo ""
echo "2. 图片格式是否正确（仅支持 JPG、PNG）"
echo ""
echo "3. 图片大小是否超过 5MB"
echo ""
echo "4. 网络连接是否正常"
echo ""
echo "5. 查看小程序控制台是否有错误信息"
echo ""

# 建议的修复步骤
echo -e "${YELLOW}建议的修复步骤：${NC}"
echo ""
echo "1. 重启服务"
echo "   docker compose restart"
echo ""
echo "2. 清理并重新构建"
echo "   docker compose down"
echo "   docker compose up -d"
echo ""
echo "3. 运行测试脚本"
echo "   bash scripts/test-upload.sh"
echo ""

echo -e "${GREEN}=========================================="
echo "诊断完成！"
echo "==========================================${NC}"
