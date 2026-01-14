#!/bin/bash
# 企业微信机器人快速部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}企业微信机器人快速部署${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# 项目目录
PROJECT_DIR="/root/tnho-fasteners"

# 检查项目目录
echo -e "${YELLOW}[1/6] 检查项目目录${NC}"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}错误: 项目目录不存在: $PROJECT_DIR${NC}"
    exit 1
fi
cd "$PROJECT_DIR"
echo -e "${GREEN}✓ 项目目录确认${NC}"

# 检查企业微信配置
echo -e "\n${YELLOW}[2/6] 检查企业微信配置${NC}"
if ! grep -q "WECHAT_CORP_ID" .env 2>/dev/null; then
    echo -e "${YELLOW}⚠ 企业微信配置未设置${NC}"
    echo ""
    echo "请输入企业微信配置信息："
    echo ""
    read -p "CorpId（企业ID）: " corp_id
    read -p "Token: " token
    read -p "EncodingAESKey: " encoding_aes_key
    echo ""

    # 添加到 .env 文件
    echo "" >> .env
    echo "# 企业微信配置" >> .env
    echo "WECHAT_CORP_ID=$corp_id" >> .env
    echo "WECHAT_TOKEN=$token" >> .env
    echo "WECHAT_ENCODING_AES_KEY=$encoding_aes_key" >> .env

    echo -e "${GREEN}✓ 企业微信配置已保存${NC}"
else
    echo -e "${GREEN}✓ 企业微信配置已存在${NC}"
    echo "配置内容："
    grep "^WECHAT_" .env
fi

# 安装依赖
echo -e "\n${YELLOW}[3/6] 安装依赖${NC}"
echo "检查已安装的依赖..."

# 检查 cryptography（用于加密解密）
if ! python3 -c "import cryptography" 2>/dev/null; then
    echo -e "${YELLOW}安装 cryptography...${NC}"
    pip3 install cryptography -i https://mirrors.aliyun.com/pypi/simple/
    echo -e "${GREEN}✓ cryptography 已安装${NC}"
else
    echo -e "${GREEN}✓ cryptography 已安装${NC}"
fi

# 测试企业微信接口
echo -e "\n${YELLOW}[4/6] 测试企业微信接口${NC}"

# 检查服务是否运行
if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    echo -e "${GREEN}✓ FastAPI 服务正在运行${NC}"
else
    echo -e "${YELLOW}⚠ FastAPI 服务未运行${NC}"
    echo "启动服务..."
    nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &
    sleep 3
    echo -e "${GREEN}✓ 服务已启动${NC}"
fi

# 测试接口
echo "测试企业微信接口..."
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9000/api/wechat/test 2>/dev/null || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ 企业微信接口测试通过${NC}"
    curl -s http://127.0.0.1:9000/api/wechat/test | python3 -m json.tool | head -10
else
    echo -e "${RED}✗ 企业微信接口测试失败 (HTTP $HEALTH_CHECK)${NC}"
    echo "查看日志："
    tail -50 app.log | grep -E "企业微信|wechat|WeChat" || echo "无相关日志"
fi

# 创建必要的目录
echo -e "\n${YELLOW}[5/6] 创建必要的目录${NC}"
mkdir -p assets/wechat/videos
mkdir -p assets/wechat/images
mkdir -p assets/wechat/voices
echo -e "${GREEN}✓ 目录创建完成${NC}"

# 显示配置信息
echo -e "\n${YELLOW}[6/6] 配置信息${NC}"
echo "=========================================="
echo "企业微信机器人配置"
echo "=========================================="
echo ""
echo "服务器信息："
echo "  IP地址: 47.110.72.148"
echo "  端口: 9000"
echo ""
echo "企业微信配置："
if grep -q "WECHAT_CORP_ID" .env 2>/dev/null; then
    echo "  CorpId: $(grep '^WECHAT_CORP_ID' .env | cut -d'=' -f2)"
    echo "  Token: $(grep '^WECHAT_TOKEN' .env | cut -d'=' -f2 | cut -c1-10)..."
    echo "  EncodingAESKey: $(grep '^WECHAT_ENCODING_AES_KEY' .env | cut -d'=' -f2 | cut -c1-10)..."
fi
echo ""
echo "企业微信回调 URL："
echo "  http://47.110.72.148/api/wechat/callback"
echo ""
echo "注意事项："
echo "  1. 在企业微信后台配置回调 URL"
echo "  2. Token 和 EncodingAESKey 必须与 .env 文件一致"
echo "  3. 域名要求：企业微信要求备案域名，当前使用 IP 地址"
echo "  4. 如果提示域名未备案，先尝试使用 IP 地址"
echo ""
echo "测试命令："
echo "  curl http://47.110.72.148/api/wechat/test"
echo ""
echo "查看日志："
echo "  tail -f $PROJECT_DIR/app.log"
echo ""

# 询问是否查看日志
read -p "是否查看应用日志？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}最近的应用日志：${NC}"
    tail -50 app.log
fi

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "下一步："
echo "1. 在企业微信后台配置回调 URL"
echo "2. URL: http://47.110.72.148/api/wechat/callback"
echo "3. Token: 与 .env 文件中的 WECHAT_TOKEN 一致"
echo "4. EncodingAESKey: 与 .env 文件中的 WECHAT_ENCODING_AES_KEY 一致"
echo "5. 保存配置后，在企业微信中测试发送消息"
echo ""
echo "文档："
echo "  配置指南: docs/ENTERPRISE_WECHAT_CONFIG.md"
echo "  使用指南: docs/ENTERPRISE_WECHAT_GUIDE.md"
echo ""
