#!/bin/bash

# 更新小程序 API 地址为 HTTPS 域名

DOMAIN="tnho-fasteners.com"
API_URL="https://${DOMAIN}"

echo "====================================="
echo "更新小程序 API 地址"
echo "====================================="
echo ""
echo "旧地址: http://47.110.72.148"
echo "新地址: ${API_URL}"
echo ""

# 读取旧文件
OLD_FILE="/workspace/projects/miniprogram/app.js"
NEW_FILE="/workspace/projects/miniprogram/app.js.new"

# 替换 API 地址
sed "s|apiUrl: 'http://47.110.72.148'|apiUrl: '${API_URL}'|g" ${OLD_FILE} > ${NEW_FILE}

# 替换文件
mv ${NEW_FILE} ${OLD_FILE}

echo "✅ 小程序 API 地址已更新为: ${API_URL}"
echo ""
echo "下一步:"
echo "  1. 在微信开发者工具中重新编译小程序"
echo "  2. 测试 HTTPS 访问"
echo ""
