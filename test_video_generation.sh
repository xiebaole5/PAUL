#!/bin/bash

# 测试天虹紧固件视频生成服务
# 用途：验证视频生成功能是否正常
# 域名：tnho-fasteners.com

echo "=========================================="
echo "天虹紧固件视频生成服务测试"
echo "=========================================="
echo "域名：tnho-fasteners.com"
echo "=========================================="

API_BASE="https://tnho-fasteners.com"

# 测试 1: 健康检查
echo ""
echo "【测试 1/5】健康检查..."
curl -s "$API_BASE/health" | jq '.' || echo "❌ 健康检查失败"
echo ""

# 测试 2: API 根路径
echo "【测试 2/5】API 根路径..."
curl -s "$API_BASE/" | jq '.' || echo "❌ 根路径访问失败"
echo ""

# 测试 3: 生成脚本（快速测试）
echo "【测试 3/5】生成 5秒 脚本..."
curl -s -X POST "$API_BASE/api/generate-video" \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 5,
    "type": "script"
  }' | jq '.success, .message, .type' || echo "❌ 脚本生成失败"
echo ""

# 测试 4: 生成视频（注意：此测试会调用火山方舟API，可能需要1-2分钟）
echo "【测试 4/5】生成 10秒 视频（测试视频生成能力）..."
echo "⚠️  注意：此测试将调用真实API，可能需要1-2分钟..."
read -p "是否继续？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "开始生成视频，请稍候..."
  START_TIME=$(date +%s)

  curl -s -X POST "$API_BASE/api/generate-video" \
    -H "Content-Type: application/json" \
    -d '{
      "product_name": "不锈钢螺丝",
      "theme": "品质保证",
      "duration": 10,
      "type": "video"
    }' > /tmp/video_test_result.json

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  echo "耗时: ${DURATION}秒"
  echo ""
  echo "结果："
  cat /tmp/video_test_result.json | jq '.success, .message, .type'
  echo ""
  echo "详细信息："
  cat /tmp/video_test_result.json | jq '.'
else
  echo "跳过视频生成测试"
fi
echo ""

# 测试 5: 查看服务日志
echo "【测试 5/5】查看服务日志（最后20行）..."
docker logs --tail 20 tnho-video-api 2>&1
echo ""

echo "=========================================="
echo "测试完成！"
echo "=========================================="
