#!/bin/bash
# 小程序域名配置验证脚本
# 使用方法: bash verify_domain_config.sh

set -e

echo "========================================="
echo "小程序域名配置验证"
echo "========================================="

DOMAIN="tnho-fasteners.com"

# 1. 验证 HTTPS 证书
echo ""
echo "1. 验证 HTTPS 证书..."
echo "----------------------------------------"

# 检查证书信息
CERT_INFO=$(echo | openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null)

if [ -n "$CERT_INFO" ]; then
    echo "✅ HTTPS 证书有效"
    echo "$CERT_INFO"
else
    echo "❌ HTTPS 证书无效或无法访问"
    exit 1
fi

# 2. 验证域名 DNS 解析
echo ""
echo "2. 验证域名 DNS 解析..."
echo "----------------------------------------"

DNS_RESULT=$(dig +short ${DOMAIN} A)

if [ -n "$DNS_RESULT" ]; then
    echo "✅ 域名解析正常"
    echo "解析到: $DNS_RESULT"
else
    echo "❌ 域名解析失败"
    exit 1
fi

# 3. 验证 API 接口访问
echo ""
echo "3. 验证 API 接口访问..."
echo "----------------------------------------"

# 测试健康检查接口
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://${DOMAIN}/health)

if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "✅ 健康检查接口访问正常"
    echo "HTTP 状态码: $HEALTH_RESPONSE"
else
    echo "❌ 健康检查接口访问失败"
    echo "HTTP 状态码: $HEALTH_RESPONSE"
    exit 1
fi

# 4. 验证图片上传接口
echo ""
echo "4. 验证图片上传接口..."
echo "----------------------------------------"

# 创建测试文件
echo "test" > /tmp/test_domain.txt

UPLOAD_RESPONSE=$(curl -s -X POST https://${DOMAIN}/api/upload-image \
  -F "file=@/tmp/test_domain.txt" | jq -r '.message' 2>/dev/null || echo "")

if [[ "$UPLOAD_RESPONSE" == *"成功"* ]]; then
    echo "✅ 图片上传接口访问正常"
else
    echo "⚠️ 图片上传接口可能有问题"
    echo "响应: $UPLOAD_RESPONSE"
fi

# 5. 验证 CORS 配置
echo ""
echo "5. 验证 CORS 配置..."
echo "----------------------------------------"

CORS_HEADERS=$(curl -s -I -X OPTIONS https://${DOMAIN}/health | grep -i "access-control" || echo "")

if [ -n "$CORS_HEADERS" ]; then
    echo "✅ CORS 配置已设置"
    echo "$CORS_HEADERS"
else
    echo "⚠️ 未检测到 CORS 配置（可能需要配置）"
fi

# 6. 验证 SSL/TLS 配置
echo ""
echo "6. 验证 SSL/TLS 配置..."
echo "----------------------------------------"

SSL_RESULT=$(echo | openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} 2>/dev/null | grep "Verify return code")

if [[ "$SSL_RESULT" == *"0 (ok)"* ]]; then
    echo "✅ SSL/TLS 配置正确"
else
    echo "⚠️ SSL/TLS 配置可能有问题"
    echo "$SSL_RESULT"
fi

# 7. 显示配置信息
echo ""
echo "7. 配置信息..."
echo "----------------------------------------"
echo "request 合法域名: https://${DOMAIN}"
echo "uploadFile 合法域名: https://${DOMAIN}"
echo "downloadFile 合法域名: https://${DOMAIN}"

echo ""
echo "========================================="
echo "验证完成！"
echo "========================================="
echo ""
echo "下一步："
echo "1. 登录微信公众平台：https://mp.weixin.qq.com/"
echo "2. 进入开发 → 开发管理 → 开发设置"
echo "3. 配置服务器域名（使用上述域名）"
echo "4. 等待 5-10 分钟后在小程序中测试"
