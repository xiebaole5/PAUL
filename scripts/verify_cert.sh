#!/bin/bash

# SSL 证书验证脚本
#
# 使用方法：
#   ./verify_cert.sh [domain]
#
# 示例：
#   ./verify_cert.sh tnho-fasteners.com
#   ./verify_cert.sh localhost

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认域名
DOMAIN="${1:-tnho-fasteners.com}"

# 显示帮助信息
show_help() {
    echo "SSL 证书验证脚本"
    echo ""
    echo "使用方法："
    echo "  $0 [domain]"
    echo ""
    echo "参数："
    echo "  domain    要验证的域名（默认：tnho-fasteners.com）"
    echo ""
    echo "示例："
    echo "  $0 tnho-fasteners.com"
    echo "  $0 localhost"
}

# 检查依赖
check_dependencies() {
    local missing_deps=()

    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}[ERROR]${NC} 缺少依赖："
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

# 验证证书
verify_certificate() {
    echo -e "${BLUE}[INFO]${NC} 验证域名：${DOMAIN}"
    echo ""

    # 获取证书信息
    local cert_info=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -text 2>/dev/null)

    if [ -z "$cert_info" ]; then
        echo -e "${RED}[ERROR]${NC} 无法获取证书信息"
        echo "请检查："
        echo "  1. 域名是否正确"
        echo "  2. HTTPS 端口是否开放"
        echo "  3. Nginx 服务是否运行"
        exit 1
    fi

    # 解析证书信息
    local subject=$(echo "$cert_info" | grep "Subject:" | sed 's/.*Subject: //')
    local issuer=$(echo "$cert_info" | grep "Issuer:" | sed 's/.*Issuer: //')
    local not_before=$(echo "$cert_info" | grep "Not Before:" | sed 's/.*Not Before: //')
    local not_after=$(echo "$cert_info" | grep "Not After:" | sed 's/.*Not After: //')
    local san=$(echo "$cert_info" | grep -A 1 "Subject Alternative Name:" | tail -1 | sed 's/.*DNS://;s/, /\n  /g')

    # 显示证书信息
    echo -e "${GREEN}[SUCCESS]${NC} 证书信息："
    echo ""
    echo "  主题 (Subject):"
    echo "    $subject"
    echo ""
    echo "  颁发者 (Issuer):"
    echo "    $issuer"
    echo ""
    echo "  有效期："
    echo "    起始：$not_before"
    echo "    截止：$not_after"
    echo ""

    # 检查有效期
    local not_after_timestamp=$(date -d "$not_after" +%s 2>/dev/null || echo "0")
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( ($not_after_timestamp - $current_timestamp) / 86400 ))

    if [ $days_until_expiry -lt 0 ]; then
        echo -e "${RED}[ERROR]${NC} 证书已过期！"
    elif [ $days_until_expiry -lt 30 ]; then
        echo -e "${YELLOW}[WARN]${NC} 证书即将过期（${days_until_expiry} 天后）"
    else
        echo -e "${GREEN}[INFO]${NC} 证书有效期：${days_until_expiry} 天"
    fi
    echo ""

    # 显示 SAN（如果有）
    if [ -n "$san" ]; then
        echo "  主题备用名称 (SAN):"
        echo "$san" | sed 's/^/    /'
        echo ""
    fi
}

# 验证 HTTPS 连接
verify_https_connection() {
    echo -e "${BLUE}[INFO]${NC} 测试 HTTPS 连接..."
    echo ""

    # 测试健康检查端点
    local response=$(curl -sk -o /dev/null -w "%{http_code}" https://$DOMAIN/health 2>/dev/null)
    local ssl_error=$(curl -sk -o /dev/null -w "%{ssl_verify_result}" https://$DOMAIN/health 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "${GREEN}[SUCCESS]${NC} HTTPS 连接正常"
        echo "  健康检查接口：${GREEN}200 OK${NC}"
        echo "  SSL 验证：${GREEN}通过${NC}"
    else
        echo -e "${RED}[ERROR]${NC} HTTPS 连接失败"
        echo "  HTTP 状态码：$response"
        echo "  SSL 验证结果：$ssl_error"
    fi
    echo ""

    # 测试 HTTP 到 HTTPS 跳转
    local redirect=$(curl -sk -I http://$DOMAIN 2>/dev/null | grep -i "location:" | head -1)
    if echo "$redirect" | grep -q "https://"; then
        echo -e "${GREEN}[SUCCESS]${NC} HTTP 自动跳转到 HTTPS"
        echo "  $redirect"
    else
        echo -e "${YELLOW}[WARN]${NC} HTTP 未自动跳转到 HTTPS"
    fi
    echo ""
}

# 验证 Cloudflare 代理
verify_cloudflare() {
    echo -e "${BLUE}[INFO]${NC} 检查 Cloudflare 代理状态..."
    echo ""

    local cf_headers=$(curl -sk -I https://$DOMAIN/health 2>/dev/null | grep -i "cf-")

    if [ -n "$cf_headers" ]; then
        echo -e "${GREEN}[SUCCESS]${NC} Cloudflare 代理已启用"
        echo "$cf_headers" | sed 's/^/  /'
    else
        echo -e "${YELLOW}[WARN]${NC} 未检测到 Cloudflare 代理"
    fi
    echo ""
}

# 主函数
main() {
    # 检查依赖
    check_dependencies

    # 验证证书
    verify_certificate

    # 验证 HTTPS 连接
    verify_https_connection

    # 验证 Cloudflare 代理
    verify_cloudflare

    # 完成
    echo -e "${GREEN}[SUCCESS]${NC} 验证完成！"
}

# 执行主函数
main "$@"
