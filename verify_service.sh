#!/bin/bash
# 服务验证测试脚本
# 使用方法: bash verify_service.sh

set -e

echo "========================================="
echo "开始验证服务..."
echo "========================================="

# 1. 检查服务状态
echo ""
echo "1. 检查服务状态..."
systemctl status tnho-api --no-pager | head -15

# 2. 测试健康检查
echo ""
echo "2. 测试健康检查接口..."
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
echo "响应: $HEALTH_RESPONSE"

if [[ "$HEALTH_RESPONSE" == *"healthy"* ]] || [[ "$HEALTH_RESPONSE" == *"ok"* ]]; then
    echo "✅ 健康检查通过"
else
    echo "❌ 健康检查失败"
fi

# 3. 测试图片上传
echo ""
echo "3. 测试图片上传接口..."

# 创建测试图片
echo "test" > /tmp/test_image.txt

UPLOAD_RESPONSE=$(curl -s -X POST http://localhost:8000/api/upload-image \
  -F "file=@/tmp/test_image.txt")

echo "响应: $UPLOAD_RESPONSE"

if [[ "$UPLOAD_RESPONSE" == *"成功"* ]] || [[ "$UPLOAD_RESPONSE" == *"url"* ]]; then
    echo "✅ 图片上传成功"
else
    echo "❌ 图片上传失败"
fi

# 4. 检查端口占用
echo ""
echo "4. 检查端口占用情况..."
lsof -i:8000 | grep LISTEN || echo "端口 8000 未被占用（异常）"

# 5. 检查服务日志
echo ""
echo "5. 查看最近的服务日志（最后10行）..."
journalctl -u tnho-api -n 10 --no-pager | tail -10

# 6. 检查服务资源使用
echo ""
echo "6. 检查服务资源使用..."
ps aux | grep "python.*app.py" | grep -v grep

# 7. 启用开机自启
echo ""
echo "7. 配置服务开机自启..."
systemctl is-enabled tnho-api || systemctl enable tnho-api
echo "服务已配置为开机自启"

echo ""
echo "========================================="
echo "验证完成！"
echo "========================================="
