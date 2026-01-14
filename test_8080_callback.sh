#!/bin/bash

echo "测试8080端口的企业微信接口..."
echo ""

# 测试1: 健康检查
echo "1. 测试健康检查接口"
curl -s http://47.110.72.148:8080/health
echo ""
echo ""

# 测试2: 企业微信测试接口
echo "2. 测试企业微信测试接口"
curl -s http://47.110.72.148:8080/api/wechat/test
echo ""
echo ""

# 测试3: 回调接口（不带参数）
echo "3. 测试回调接口（不带参数）"
curl -s -w "\nHTTP状态码: %{http_code}\n" http://47.110.72.148:8080/api/wechat/callback
echo ""

