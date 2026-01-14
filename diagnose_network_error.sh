#!/bin/bash
# 快速诊断网络请求错误
# 使用方法: bash diagnose_network_error.sh

set -e

echo "========================================="
echo "网络请求错误快速诊断"
echo "========================================="

DOMAIN="tnho-fasteners.com"

# 1. 检查服务状态
echo ""
echo "1. 检查服务状态..."
echo "----------------------------------------"
systemctl status tnho-api --no-pager | head -15

# 2. 检查 Nginx 状态
echo ""
echo "2. 检查 Nginx 状态..."
echo "----------------------------------------"
systemctl status nginx --no-pager | head -10

# 3. 测试 HTTPS 连接
echo ""
echo "3. 测试 HTTPS 连接..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://${DOMAIN}/health)
echo "HTTP 状态码: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTPS 连接正常"
else
    echo "❌ HTTPS 连接失败"
fi

# 4. 测试健康检查接口
echo ""
echo "4. 测试健康检查接口..."
echo "----------------------------------------"
HEALTH_RESPONSE=$(curl -s https://${DOMAIN}/health)
echo "响应: $HEALTH_RESPONSE"

if [[ "$HEALTH_RESPONSE" == *"ok"* ]]; then
    echo "✅ 健康检查接口正常"
else
    echo "❌ 健康检查接口异常"
fi

# 5. 测试图片上传接口
echo ""
echo "5. 测试图片上传接口..."
echo "----------------------------------------"
echo "test" > /tmp/test_diagnose.txt

UPLOAD_RESPONSE=$(curl -s -X POST https://${DOMAIN}/api/upload-image \
  -F "file=@/tmp/test_diagnose.txt")

echo "响应: $UPLOAD_RESPONSE"

if [[ "$UPLOAD_RESPONSE" == *"成功"* ]]; then
    echo "✅ 图片上传接口正常"
else
    echo "❌ 图片上传接口异常"
    echo ""
    echo "详细错误信息："
    curl -X POST https://${DOMAIN}/api/upload-image \
      -F "file=@/tmp/test_diagnose.txt" -v 2>&1 | tail -20
fi

# 6. 检查 HTTPS 证书
echo ""
echo "6. 检查 HTTPS 证书..."
echo "----------------------------------------"
CERT_DATES=$(echo | openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "无法获取证书信息")

if [ -n "$CERT_DATES" ]; then
    echo "✅ HTTPS 证书有效"
    echo "$CERT_DATES"
else
    echo "❌ HTTPS 证书无效或无法访问"
fi

# 7. 检查端口占用
echo ""
echo "7. 检查端口占用..."
echo "----------------------------------------"
lsof -i:8000 | grep LISTEN || echo "端口 8000 未被监听"
lsof -i:443 | grep LISTEN || echo "端口 443 未被监听"

# 8. 查看最近的错误日志
echo ""
echo "8. 查看最近的错误日志..."
echo "----------------------------------------"
journalctl -u tnho-api -n 20 --no-pager | grep -i error || echo "没有发现错误日志"

# 9. 查看最近的 Nginx 错误日志
echo ""
echo "9. 查看最近的 Nginx 错误日志..."
echo "----------------------------------------"
sudo tail -20 /var/log/nginx/error.log 2>/dev/null || echo "无法读取 Nginx 错误日志"

# 10. 诊断总结
echo ""
echo "========================================="
echo "诊断总结"
echo "========================================="

ALL_OK=true

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ HTTPS 连接失败"
    ALL_OK=false
fi

if [[ ! "$HEALTH_RESPONSE" == *"ok"* ]]; then
    echo "❌ 健康检查接口异常"
    ALL_OK=false
fi

if [[ ! "$UPLOAD_RESPONSE" == *"成功"* ]]; then
    echo "❌ 图片上传接口异常"
    ALL_OK=false
fi

if [ "$ALL_OK" = true ]; then
    echo ""
    echo "✅ 所有检查通过！"
    echo ""
    echo "可能的问题："
    echo "1. 域名配置未生效（需要等待 5-10 分钟）"
    echo "2. 小程序端配置问题"
    echo "3. Cloudflare CDN 缓存问题"
    echo ""
    echo "建议操作："
    echo "1. 在小程序开发者工具中勾选 '不校验合法域名' 进行测试"
    echo "2. 等待 10 分钟后重新测试"
    echo "3. 清除 Cloudflare 缓存（如果使用）"
else
    echo ""
    echo "❌ 发现问题，请检查上述详细信息"
    echo ""
    echo "建议操作："
    echo "1. 重启服务：systemctl restart tnho-api"
    echo "2. 重启 Nginx：systemctl reload nginx"
    echo "3. 查看详细日志：journalctl -u tnho-api -f"
fi

echo ""
echo "========================================="
