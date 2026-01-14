#!/bin/bash

# Cloudflare Bot Fight Mode 快速禁用脚本
# 使用方法：./disable_bot_fight_mode.sh

echo "========================================"
echo "Cloudflare Bot Fight Mode 禁用工具"
echo "========================================"
echo ""

# 检查是否设置了 API Token
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "❌ 错误：请先设置 CLOUDFLARE_API_TOKEN 环境变量"
    echo ""
    echo "使用方法："
    echo "  export CLOUDFLARE_API_TOKEN='your_api_token_here'"
    echo "  export CLOUDFLARE_ZONE_ID='your_zone_id_here'"
    echo "  ./disable_bot_fight_mode.sh"
    echo ""
    exit 1
fi

if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    echo "❌ 错误：请先设置 CLOUDFLARE_ZONE_ID 环境变量"
    echo ""
    exit 1
fi

API_TOKEN=$CLOUDFLARE_API_TOKEN
ZONE_ID=$CLOUDFLARE_ZONE_ID

echo "正在关闭 Bot Fight Mode..."
echo ""

# 使用 curl 禁用 Bot Fight Mode
RESPONSE=$(curl -s -X PATCH \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/bot_fight_mode" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"value":"off"}')

# 检查响应
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ 成功：Bot Fight Mode 已关闭"
    echo ""
    echo "当前设置："
    echo "$RESPONSE" | python3 -m json.tool | grep -A 5 '"result"'
else
    echo "❌ 失败：无法关闭 Bot Fight Mode"
    echo ""
    echo "错误详情："
    echo "$RESPONSE" | python3 -m json.tool
    exit 1
fi

echo ""
echo "========================================"
echo "下一步："
echo "========================================"
echo "1. 清除 Cloudflare 缓存："
echo "   https://dash.cloudflare.com -> Caching -> Configuration -> Purge everything"
echo ""
echo "2. 清除小程序缓存："
echo "   微信开发者工具 -> 工具 -> 清缓存 -> 清除全部缓存"
echo ""
echo "3. 重新编译小程序并测试"
echo "========================================"
