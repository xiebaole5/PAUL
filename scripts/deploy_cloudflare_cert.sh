#!/bin/bash

# Cloudflare Origin Certificate 部署脚本
#
# 使用方法：
#   ./deploy_cloudflare_cert.sh --cert ./certs/cloudflare-origin.crt --key ./certs/cloudflare-origin.key
#
# 或者直接指定服务器 IP：
#   ./deploy_cloudflare_cert.sh --cert ./certs/cloudflare-origin.crt --key ./certs/cloudflare-origin.key --server 47.110.72.148

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_SERVER="47.110.72.148"
REMOTE_CERT_PATH="/etc/nginx/ssl/tnho-origin.crt"
REMOTE_KEY_PATH="/etc/nginx/ssl/tnho-origin.key"
NGINX_CONFIG_PATH="/etc/nginx/sites-available/tnho-https.conf"

# 显示帮助信息
show_help() {
    echo "Cloudflare Origin Certificate 部署脚本"
    echo ""
    echo "使用方法："
    echo "  $0 [选项]"
    echo ""
    echo "选项："
    echo "  --cert <路径>     证书文件路径（必需）"
    echo "  --key <路径>      私钥文件路径（必需）"
    echo "  --server <IP>     服务器 IP 地址（默认：$DEFAULT_SERVER）"
    echo "  --user <用户>     SSH 用户名（默认：root）"
    echo "  --port <端口>     SSH 端口（默认：22）"
    echo "  --dry-run         仅显示将要执行的命令，不实际执行"
    echo "  -h, --help        显示帮助信息"
    echo ""
    echo "示例："
    echo "  $0 --cert ./certs/cloudflare-origin.crt --key ./certs/cloudflare-origin.key"
    echo "  $0 --cert ./certs/cloudflare-origin.crt --key ./certs/cloudflare-origin.key --server 47.110.72.148"
}

# 解析命令行参数
CERT_FILE=""
KEY_FILE=""
SERVER_IP="$DEFAULT_SERVER"
SSH_USER="root"
SSH_PORT="22"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cert)
            CERT_FILE="$2"
            shift 2
            ;;
        --key)
            KEY_FILE="$2"
            shift 2
            ;;
        --server)
            SERVER_IP="$2"
            shift 2
            ;;
        --user)
            SSH_USER="$2"
            shift 2
            ;;
        --port)
            SSH_PORT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} 未知选项：$1"
            show_help
            exit 1
            ;;
    esac
done

# 检查必需参数
if [[ -z "$CERT_FILE" ]]; then
    echo -e "${RED}[ERROR]${NC} 缺少必需参数：--cert"
    show_help
    exit 1
fi

if [[ -z "$KEY_FILE" ]]; then
    echo -e "${RED}[ERROR]${NC} 缺少必需参数：--key"
    show_help
    exit 1
fi

# 检查文件是否存在
if [[ ! -f "$CERT_FILE" ]]; then
    echo -e "${RED}[ERROR]${NC} 证书文件不存在：$CERT_FILE"
    exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
    echo -e "${RED}[ERROR]${NC} 私钥文件不存在：$KEY_FILE"
    exit 1
fi

# 显示配置信息
echo -e "${BLUE}[INFO]${NC} 部署配置："
echo "  服务器：$SSH_USER@$SERVER_IP:$SSH_PORT"
echo "  证书：$CERT_FILE -> $REMOTE_CERT_PATH"
echo "  私钥：$KEY_FILE -> $REMOTE_KEY_PATH"
echo ""

# 确认操作
if [[ "$DRY_RUN" = false ]]; then
    read -p "确认部署？(y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[INFO]${NC} 已取消部署"
        exit 0
    fi
fi

# 构建 SSH 命令
SSH_CMD="ssh -p $SSH_PORT $SSH_USER@$SERVER_IP"
SCP_CMD="scp -P $SSH_PORT"

echo -e "${GREEN}[INFO]${NC} 开始部署..."

# 备份现有证书
echo -e "${BLUE}[INFO]${NC} 备份现有证书..."
if [[ "$DRY_RUN" = false ]]; then
    $SSH_CMD "cp $REMOTE_CERT_PATH ${REMOTE_CERT_PATH}.backup.$(date +%Y%m%d%H%M%S) 2>/dev/null || true"
    $SSH_CMD "cp $REMOTE_KEY_PATH ${REMOTE_KEY_PATH}.backup.$(date +%Y%m%d%H%M%S) 2>/dev/null || true"
    echo -e "${GREEN}[SUCCESS]${NC} 备份完成"
else
    echo "[DRY-RUN] $SSH_CMD \"cp $REMOTE_CERT_PATH ${REMOTE_CERT_PATH}.backup...\""
fi

# 上传证书
echo -e "${BLUE}[INFO]${NC} 上传证书..."
if [[ "$DRY_RUN" = false ]]; then
    $SCP_CMD "$CERT_FILE" "$SSH_USER@$SERVER_IP:$REMOTE_CERT_PATH"
    $SCP_CMD "$KEY_FILE" "$SSH_USER@$SERVER_IP:$REMOTE_KEY_PATH"
    echo -e "${GREEN}[SUCCESS]${NC} 证书上传完成"
else
    echo "[DRY-RUN] $SCP_CMD $CERT_FILE $SSH_USER@$SERVER_IP:$REMOTE_CERT_PATH"
    echo "[DRY-RUN] $SCP_CMD $KEY_FILE $SSH_USER@$SERVER_IP:$REMOTE_KEY_PATH"
fi

# 设置正确的权限
echo -e "${BLUE}[INFO]${NC} 设置证书权限..."
if [[ "$DRY_RUN" = false ]]; then
    $SSH_CMD "chmod 644 $REMOTE_CERT_PATH"
    $SSH_CMD "chmod 600 $REMOTE_KEY_PATH"
    echo -e "${GREEN}[SUCCESS]${NC} 权限设置完成"
else
    echo "[DRY-RUN] $SSH_CMD \"chmod 644 $REMOTE_CERT_PATH\""
    echo "[DRY-RUN] $SSH_CMD \"chmod 600 $REMOTE_KEY_PATH\""
fi

# 测试 Nginx 配置
echo -e "${BLUE}[INFO]${NC} 测试 Nginx 配置..."
if [[ "$DRY_RUN" = false ]]; then
    if $SSH_CMD "nginx -t"; then
        echo -e "${GREEN}[SUCCESS]${NC} Nginx 配置测试通过"
    else
        echo -e "${RED}[ERROR]${NC} Nginx 配置测试失败"
        echo -e "${YELLOW}[WARN]${NC} 已回滚到备份证书"
        $SSH_CMD "cp ${REMOTE_CERT_PATH}.backup.* $REMOTE_CERT_PATH 2>/dev/null || true"
        $SSH_CMD "cp ${REMOTE_KEY_PATH}.backup.* $REMOTE_KEY_PATH 2>/dev/null || true"
        exit 1
    fi
else
    echo "[DRY-RUN] $SSH_CMD \"nginx -t\""
fi

# 重启 Nginx
echo -e "${BLUE}[INFO]${NC} 重启 Nginx..."
if [[ "$DRY_RUN" = false ]]; then
    $SSH_CMD "nginx -s reload"
    sleep 2
    echo -e "${GREEN}[SUCCESS]${NC} Nginx 重启完成"
else
    echo "[DRY-RUN] $SSH_CMD \"nginx -s reload\""
fi

# 验证证书
echo -e "${BLUE}[INFO]${NC} 验证证书..."
if [[ "$DRY_RUN" = false ]]; then
    CERT_INFO=$($SSH_CMD "openssl x509 -in $REMOTE_CERT_PATH -noout -subject -issuer -dates 2>/dev/null")
    if [[ -n "$CERT_INFO" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} 证书信息："
        echo "$CERT_INFO" | sed 's/^/  /'
    else
        echo -e "${YELLOW}[WARN]${NC} 无法获取证书信息"
    fi
else
    echo "[DRY-RUN] $SSH_CMD \"openssl x509 -in $REMOTE_CERT_PATH -noout -subject -issuer -dates\""
fi

# 完成
echo ""
echo -e "${GREEN}[SUCCESS]${NC} 部署完成！"
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
echo "  3. 测试小程序："
echo "     - 打开微信开发者工具"
echo "     - 刷新小程序"
echo "     - 应该可以正常访问 API 了"
echo ""
